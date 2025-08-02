package modtemplate.net;

#if MC_VER >= MC_1_20_5
import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
#else

import net.minecraft.network.FriendlyByteBuf;
#endif
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import org.jetbrains.annotations.NotNull;

public record HelloPacket(
        String message
) implements CustomPacketPayload {

    #if MC_VER >= MC_1_20_5
    public static final StreamCodec<RegistryFriendlyByteBuf, HelloPacket> STREAM_CODEC = StreamCodec.composite(
            ByteBufCodecs.STRING_UTF8, HelloPacket::message,
            HelloPacket::new);
    #endif

    #if MC_VER >= MC_1_21
    public static final Type<HelloPacket> ID = new Type<>(ResourceLocation.parse("template:hello"));
    #else
        #if MC_VER >= MC_1_20_5
    public static final Type<HelloPacket> ID = new Type<>(ResourceLocation.tryParse("template:hello"));
        #else
    public static final ResourceLocation ID = new ResourceLocation("template", "hello");
        #endif
    #endif

    #if MC_VER >= MC_1_20_5
    @Override
    public @NotNull Type<? extends CustomPacketPayload> type() {
        return ID;
    }
    #else
    @Override
    public @NotNull ResourceLocation id() {
        return ID;
    }

    @Override
    public void write(FriendlyByteBuf friendlyByteBuf) {
        friendlyByteBuf.writeUtf(message);
    }

#endif
}
