package modtemplate.paper;

import modtemplate.common.CommonEntrypoint;
import org.bukkit.plugin.java.JavaPlugin;

public final class PaperModTemplatePlugin extends JavaPlugin {

    @Override
    public void onEnable() {
        getLogger().info(() -> "Enabling " + getName() + " v" + getDescription().getVersion());
        getLogger().info(() -> "Detected Paper/MC version: " + getServer().getMinecraftVersion());

        CommonEntrypoint.logHello("Paper", getServer().getMinecraftVersion());
    }

    @Override
    public void onDisable() {
        getLogger().info(() -> "Disabling " + getName());
    }
}
