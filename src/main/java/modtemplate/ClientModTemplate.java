package modtemplate;

import net.fabricmc.api.ClientModInitializer;
#if MC_VER >= MC_1_20_5
import modtemplate.net.HelloPacket;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
#endif
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ClientModTemplate implements ClientModInitializer {

    public static final String MOD_ID = BuildInfo.artifact();
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitializeClient() {
        LOGGER.info("Hello Fabric world!");

        LOGGER.info("BuildInfo: version={}, group={}, artifact={}, commit={}, branch={}, targetMCVersion={}", BuildInfo.version(), BuildInfo.group(), BuildInfo.artifact(), BuildInfo.commit(), BuildInfo.branch(), BuildInfo.mcVersion());

        #if MC_VER >= MC_1_20_5
        PayloadTypeRegistry.playC2S().register(HelloPacket.ID, HelloPacket.STREAM_CODEC);
        PayloadTypeRegistry.playS2C().register(HelloPacket.ID, HelloPacket.STREAM_CODEC);
        #else

        #endif
    }
}