// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import peersim.config.Configuration;
import peersim.core.CommonState;
import peersim.core.Control;
import peersim.core.Network;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * Uses a data provider to get the inputs to nodes for every round. Updates the inputs of the nodes using that data.
 */

public class InputUpdater implements Control {
    private static final String PAR_PROT = "protocol";
    private static final String PAR_DATA_PROVIDER = "dataProvider";
    private static final String PAR_START_DTM = "startDtm";
    private static final String PAR_CYCLE_LENGTH = "cycleLength";
    private static final String PAR_HIDE_NA = "hideNa";

    /**
     * Protocol to operate on.
     */
    private final int protocolID;
    /**
     * Toggle whether to hide Not Available values from nodes.
     * If set to true, the input of a node is ot updated if the updated value would be a NA.
     */
    private final boolean hideNa;
    private final IDataProvider dataProvider;
    /**
     * Real time start date in UTC
     */
    private final LocalDateTime start;
    /**
     * Real world time equivalent of a simulation cycle in milli seconds
     */
    private final long cycleLength;


    public InputUpdater(String name) {
        protocolID = Configuration.getPid(name + "." + PAR_PROT);
        dataProvider = (IDataProvider) Configuration.getInstance(name + "." + PAR_DATA_PROVIDER);
        start = LocalDateTime.parse(Configuration.getString(name + "." + PAR_START_DTM));
        cycleLength = Configuration.getLong(name + "." + PAR_CYCLE_LENGTH);
        hideNa = Configuration.contains(name + "." + PAR_HIDE_NA);

    }

    public boolean execute() {
        var data = dataProvider.nodeValuesAt(start.plus(Duration.ofMillis((CommonState.getIntTime() + 1) * cycleLength)));

        for (int i = 0; i < Network.size(); i++) {
            TSProtocol protocol = (TSProtocol) Network.get(i).getProtocol(protocolID);
            if (!hideNa || !Double.isNaN(data.get(i))) {
                protocol.setInput(data.get(i));
            }
        }

        return false;
    }
}
