package modtemplate.forge;

import modtemplate.common.CommonEntrypoint;
import net.neoforged.fml.common.Mod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Mod(ModTemplateForge.MOD_ID)
public final class ModTemplateForge {

    public static final String MOD_ID = "modtemplate";
    private static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    public ModTemplateForge() {
        LOGGER.info("Hello from the NeoForge side!");
        CommonEntrypoint.logHello("NeoForge", System.getProperty("mod.mcVersion", "unknown"));
    }
}
