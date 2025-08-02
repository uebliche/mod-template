package modtemplate;

import net.fabricmc.api.DedicatedServerModInitializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ServerModTemplate implements DedicatedServerModInitializer {

    public static final String MOD_ID = BuildInfo.artifact();
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);


    @Override
    public void onInitializeServer() {
        LOGGER.info("Hello Fabric server world!");

        LOGGER.info("BuildInfo: version={}, group={}, artifact={}, commit={}, branch={}", BuildInfo.version(), BuildInfo.group(), BuildInfo.artifact(), BuildInfo.commit(), BuildInfo.branch());
    }
}
