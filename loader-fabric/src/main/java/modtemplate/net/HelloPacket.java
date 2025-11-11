package modtemplate.net;

#if MC_VER >= MC_1_20_5
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
#else

import net.minecraft.network.FriendlyByteBuf;
#endif
#if MC_VER > MC_1_20_1
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
#endif
import net.minecraft.resources.ResourceLocation;
import org.jetbrains.annotations.NotNull;

public record HelloPacket(
        String message
)
        #if MC_VER > MC_1_20_1
        implements CustomPacketPayload
        #endif {

    #if MC_VER >= MC_1_20_5
    public static final StreamCodec<RegistryFriendlyByteBuf, HelloPacket> STREAM_CODEC = StreamCodec.composite(
            ByteBufCodecs.STRING_UTF8, HelloPacket::message,
            HelloPacket::new);
    #endif
    #if MC_VER >= MC_1_21
    public static final CustomPacketPayload.Type<HelloPacket> ID = new CustomPacketPayload.Type<>(ResourceLocation.parse("template:hello"));
    #elif MC_VER >= MC_1_20_5
    public static final CustomPacketPayload.Type<HelloPacket> ID = new CustomPacketPayload.Type<>(ResourceLocation.tryParse("template:hello"));
    #else
    public static final ResourceLocation ID = new ResourceLocation("template", "hello");
    #endif

    #if MC_VER >= MC_1_20_5
    @Override
    public @NotNull CustomPacketPayload.Type<? extends CustomPacketPayload> type() {
        return ID;
    }
    #else
    #if MC_VER > MC_1_20_1
    @Override
    #endif
    public @NotNull ResourceLocation id() {
        return ID;
    }

    #if MC_VER > MC_1_20_1
    @Override
    #endif
    public void write(FriendlyByteBuf friendlyByteBuf) {
        friendlyByteBuf.writeUtf(message);
    }

#endif
}
