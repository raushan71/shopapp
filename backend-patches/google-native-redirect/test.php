<?php

// Standalone controller regression checks; no real OAuth requests or secrets.
namespace Illuminate\Http {
    class Request
    {
        private $data;
        public function __construct(array $data) { $this->data = $data; }
        public function __get($key) { return $this->input($key); }
        public function input($key) { return $this->data[$key] ?? null; }
        public function validate($rules)
        {
            if (! $this->input('code')) { throw new \RuntimeException('Missing code'); }
        }
    }
    class Response
    {
        const HTTP_FORBIDDEN = 403;
        const HTTP_BAD_REQUEST = 400;
    }
}

namespace App\Http\Controllers {
    class Controller
    {
        protected function json($message, $data, $status = 200)
        {
            return ['message' => $message, 'data' => $data, 'status' => $status];
        }
    }
}

namespace App\Http\Resources {
    class UserResource
    {
        public $user;
        public function __construct($user) { $this->user = $user; }
    }
}

namespace App\Models {
    class SocialAuth
    {
        public static $enabled = true;
        public static function where($field, $value) { return new self; }
        public function first()
        {
            return (object) [
                'is_active' => self::$enabled,
                'client_id' => 'test-web-client',
                'client_secret' => 'test-only-placeholder',
            ];
        }
    }
}

namespace App\Repositories {
    class UserRepository
    {
        public static $profiles = [];
        public static function socialAuthCheckOrCreate($data, $provider)
        {
            self::$profiles[] = $data;
            return (object) ['id' => 42, 'email' => $data['email']];
        }
        public static function getAccessToken($user) { return ['token' => 'shop-token']; }
    }
}

namespace {
    if (isset($argv[2])) { require $argv[2]; }

    class Google_Client
    {
        public static $exchanges = [];
        public static $response = ['access_token' => 'verified-google-access-token'];
        private $clientId;
        private $redirectUri;
        public function setClientId($value) { $this->clientId = $value; }
        public function setClientSecret($value) {}
        public function setRedirectUri($value) { $this->redirectUri = $value; }
        public function setAccessToken($value) {}
        public function fetchAccessTokenWithAuthCode($code)
        {
            if (class_exists(\Google\Auth\OAuth2::class)) {
                // Exercise the real library's redirect validation without HTTP.
                new \Google\Auth\OAuth2(['redirectUri' => $this->redirectUri]);
            }
            self::$exchanges[] = [$code, $this->redirectUri, $this->clientId];
            return self::$response;
        }
    }

    class Google_Service_Oauth2
    {
        public $userinfo;
        public function __construct($client)
        {
            $this->userinfo = new class {
                public function get()
                {
                    return (object) [
                        'id' => 'google-user-id', 'name' => 'Customer',
                        'email' => 'verified@example.test', 'picture' => null, 'gender' => null,
                    ];
                }
            };
        }
    }

    require $argv[1] ?? __DIR__.'/SocialAuthController.php';

    function check($condition, $message)
    {
        if (! $condition) { throw new \RuntimeException($message); }
    }

    $controller = new \App\Http\Controllers\API\SocialAuthController;
    $cases = [
        ['android', null], ['ios', null], ['web', 'postmessage'],
        [null, 'postmessage'], ['desktop', 'postmessage'],
    ];
    foreach ($cases as [$platform, $expectedRedirect]) {
        $data = [
            'code' => 'fresh-server-code',
            'redirect_uri' => 'https://untrusted.example/callback',
            'data' => ['email' => 'unverified@example.test'],
        ];
        if ($platform !== null) { $data['device_type'] = $platform; }
        $result = $controller->handleTokenExchange('google', new \Illuminate\Http\Request($data));
        $exchange = end(Google_Client::$exchanges);
        check($exchange === ['fresh-server-code', $expectedRedirect, 'test-web-client'], 'Wrong OAuth exchange configuration');
        check($result['status'] === 200, 'Expected login success');
        check($result['data']['access']['token'] === 'shop-token', 'Missing shop session');
        check($result['data']['user']->user->email === 'verified@example.test', 'Trusted client-supplied profile');
        echo 'PASS: '.($platform ?? 'missing platform')." redirect and session\n";
    }

    $profilesBefore = count(\App\Repositories\UserRepository::$profiles);
    Google_Client::$response = ['error' => 'invalid_grant'];
    $result = $controller->handleTokenExchange('google', new \Illuminate\Http\Request([
        'code' => 'rejected-code', 'device_type' => 'android',
    ]));
    check($result['status'] === 400 && $result['message'] === 'Error: invalid_grant', 'Google rejection was not preserved');
    check(count(\App\Repositories\UserRepository::$profiles) === $profilesBefore, 'Created a session for a rejected Google code');
    echo "PASS: rejected Google code creates no shop session\n";

    \App\Models\SocialAuth::$enabled = false;
    $exchangesBefore = count(Google_Client::$exchanges);
    $result = $controller->handleTokenExchange('google', new \Illuminate\Http\Request([
        'code' => 'disabled-provider-code', 'device_type' => 'ios',
    ]));
    check($result['status'] === 403, 'Disabled Google provider was accepted');
    check(count(Google_Client::$exchanges) === $exchangesBefore, 'Contacted Google for a disabled provider');
    check(count(\App\Repositories\UserRepository::$profiles) === $profilesBefore, 'Created a session for a disabled provider');
    echo "PASS: disabled provider is rejected before token exchange\n";
    echo "7 backend regression cases passed.\n";
}
