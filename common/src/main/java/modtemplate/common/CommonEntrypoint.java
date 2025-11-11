package modtemplate.common;

public final class CommonEntrypoint {

    private CommonEntrypoint() {}

    public static final String MOD_ID = "modtemplate";

    public static void logHello(String loader, String mcVersion) {
        System.out.println("[" + loader + "] Mod Template shared init for MC " + mcVersion);
    }
}
