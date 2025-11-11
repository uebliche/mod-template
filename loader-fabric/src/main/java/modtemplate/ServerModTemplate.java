package modtemplate;

import modtemplate.common.CommonEntrypoint;
import modtemplate.net.HelloPacket;
import net.fabricmc.api.DedicatedServerModInitializer;

#if MC_VER >= MC_1_20_5
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
#endif
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ServerModTemplate implements DedicatedServerModInitializer {

    public static final String MOD_ID = BuildInfo.artifact();
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitializeServer() {
        LOGGER.info("Hello Fabric server world!");

        LOGGER.info("BuildInfo: version={}, group={}, artifact={}, commit={}, branch={}, targetMCVersion={}, versionType={}", BuildInfo.version(), BuildInfo.group(), BuildInfo.artifact(), BuildInfo.commit(), BuildInfo.branch(), BuildInfo.mcVersion(), BuildInfo.versionType());
        CommonEntrypoint.logHello("Fabric-Server", BuildInfo.mcVersion());
         #if MC_VER >= MC_1_20_5
        PayloadTypeRegistry.playC2S().register(HelloPacket.ID, HelloPacket.STREAM_CODEC);
        PayloadTypeRegistry.playS2C().register(HelloPacket.ID, HelloPacket.STREAM_CODEC);
        ServerPlayNetworking.registerGlobalReceiver(HelloPacket.ID, (packet, player) -> {
            LOGGER.info("Received message from client: {}", packet.message());
        });
        #else
        ServerPlayNetworking.registerGlobalReceiver(HelloPacket.ID, (minecraftServer, serverPlayer, serverGamePacketListener, friendlyByteBuf, packetSender) -> {
            HelloPacket helloPacket = new HelloPacket(friendlyByteBuf.readUtf());
            LOGGER.info("Received message from client: {}", helloPacket.message());
        });
        #endif
    }
}
