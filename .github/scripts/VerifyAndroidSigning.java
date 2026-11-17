import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.UnrecoverableKeyException;
import java.util.HexFormat;
import java.util.Properties;

/** Verifies signing credentials without printing passwords or modifying the keystore. */
public class VerifyAndroidSigning {
    public static void main(String[] args) throws Exception {
        if (args.length < 1 || args.length > 2) {
            fail("Usage: java VerifyAndroidSigning.java <keystore> [key.properties]");
            return;
        }

        Properties localProperties = new Properties();
        if (args.length == 2) {
            try (InputStream input = Files.newInputStream(Path.of(args[1]))) {
                localProperties.load(input);
            }
        }
        String alias = setting(localProperties, "keyAlias", "KEY_ALIAS", args.length == 2);
        char[] storePassword = setting(localProperties, "storePassword", "KEYSTORE_PASSWORD", args.length == 2).toCharArray();
        char[] keyPassword = setting(localProperties, "keyPassword", "KEY_PASSWORD", args.length == 2).toCharArray();

        KeyStore store;
        try {
            store = KeyStore.getInstance(Path.of(args[0]).toFile(), storePassword);
        } catch (Exception error) {
            fail("Cannot open the release keystore. Check KEYSTORE_BASE64 and KEYSTORE_PASSWORD.");
            return;
        }
        if (!store.isKeyEntry(alias)) {
            fail("KEY_ALIAS must identify a private-key entry in this keystore.");
            return;
        }

        try {
            if (!(store.getKey(alias, keyPassword) instanceof PrivateKey)) {
                fail("KEY_ALIAS does not identify an Android signing private key.");
                return;
            }
        } catch (UnrecoverableKeyException error) {
            boolean storePasswordUnlocksKey = false;
            try {
                storePasswordUnlocksKey = store.getKey(alias, storePassword) instanceof PrivateKey;
            } catch (Exception ignored) {
                // Report the incorrect key password without disclosing either password.
            }
            if (storePasswordUnlocksKey) {
                fail("KEY_PASSWORD is incorrect. For this keystore, the private key uses the keystore password; set KEY_PASSWORD to the same value as KEYSTORE_PASSWORD.");
            } else {
                fail("KEY_PASSWORD cannot unlock the private key. Set it to the actual key password for KEY_ALIAS in the keystore uploaded as KEYSTORE_BASE64.");
            }
            return;
        }

        System.out.println("Release keystore and private-key passwords verified (" + store.getType() + ").");
        if (args.length == 2) {
            System.out.println("Store and key passwords are identical: " + java.util.Arrays.equals(storePassword, keyPassword));
        }
        byte[] certificate = store.getCertificate(alias).getEncoded();
        for (String algorithm : new String[] {"SHA-1", "SHA-256"}) {
            byte[] digest = MessageDigest.getInstance(algorithm).digest(certificate);
            System.out.println(algorithm + ": " + HexFormat.ofDelimiter(":").withUpperCase().formatHex(digest));
        }
    }

    private static String setting(Properties properties, String property, String environment, boolean local) {
        String value = local ? properties.getProperty(property) : System.getenv(environment);
        if (value == null || value.isEmpty()) {
            fail("Missing signing setting: " + (local ? property : environment));
        }
        return value;
    }

    private static void fail(String message) {
        System.err.println("::error::" + message);
        System.exit(1);
    }
}
