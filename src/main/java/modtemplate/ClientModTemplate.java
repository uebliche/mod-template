package modtemplate;

import net.fabricmc.api.ClientModInitializer;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ClientModTemplate implements ClientModInitializer {
	public static final String MOD_ID = BuildInfo.artifact();

	public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

	@Override
	public void onInitializeClient() {
		LOGGER.info("Hello Fabric world!");

		LOGGER.info("BuildInfo: version={}, group={}, artifact={}, commit={}, branch={}", BuildInfo.version(), BuildInfo.group(), BuildInfo.artifact(), BuildInfo.commit(), BuildInfo.branch());
	}
}