package modtemplate.net;

import net.minecraft.network.RegistryFriendlyByteBuf;
import net.minecraft.network.codec.ByteBufCodecs;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.ResourceLocation;
import org.jetbrains.annotations.NotNull;

public record HelloPacket(
        String message
) implements CustomPacketPayload {

    public static final StreamCodec<RegistryFriendlyByteBuf, HelloPacket> STREAM_CODEC = StreamCodec.composite(
            ByteBufCodecs.STRING_UTF8, HelloPacket::message,
            HelloPacket::new);

    public static final Type<HelloPacket> ID = new Type<>(ResourceLocation.parse("template:hello"));

    @Override
    public @NotNull Type<? extends CustomPacketPayload> type() {
        return ID;
    }
}
