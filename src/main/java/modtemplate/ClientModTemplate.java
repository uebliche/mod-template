package modtemplate;

import modtemplate.net.HelloPacket;
import net.fabricmc.api.ClientModInitializer;
#if MC_VER >= MC_1_20_5
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
#else
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayConnectionEvents;
import net.minecraft.network.FriendlyByteBuf;
#endif
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
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

        ClientPlayNetworking.registerGlobalReceiver(HelloPacket.ID, (packet, context) -> {
            LOGGER.info("Received message from server: {}", packet.message());
        });

        ClientPlayConnectionEvents.JOIN.register((clientPacketListener, packetSender, minecraft) -> {
            ClientPlayNetworking.send(new HelloPacket("Hello from the client!"));
        });
        #else
        ClientPlayNetworking.registerGlobalReceiver(HelloPacket.ID, (minecraftClient, clientPlayNetworkHandler, friendlyByteBuf, packetSender) -> {
            HelloPacket helloPacket = new HelloPacket(friendlyByteBuf.readUtf());
            LOGGER.info("Received message from server: {}", helloPacket.message());
        });

        ClientPlayConnectionEvents.JOIN.register((handler, sender, client) -> {
            FriendlyByteBuf buffer = PacketByteBufs.create();
            buffer.writeUtf("Hello from the client!");
            ClientPlayNetworking.send(HelloPacket.ID, buffer);
            LOGGER.info("Sent hello message to server.");
        });
        #endif
    }
}