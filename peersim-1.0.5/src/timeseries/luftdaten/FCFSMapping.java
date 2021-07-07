// Author: Alexander Weinmann uni@aweinmann.de
package timeseries.luftdaten;

import java.util.HashMap;

/**
 * Maps nodes to sensors on a first come first served basis.
 * Once a node is mapped to a sensor it cannot be unmapped.
 */
public class FCFSMapping {
    private final HashMap<Integer, String> nodeToSensor = new HashMap<>();
    private final HashMap<String, Integer> sensorToNode = new HashMap<>();
    private int nextNodeId = 0;


    public void sensorToNode(String sensorId, int nodeId) {
        sensorToNode.put(sensorId, nodeId);
        nodeToSensor.put(nodeId, sensorId);
    }

    public void nodeToSensor(int nodeId, String sensorId) {
        sensorToNode(sensorId, nodeId);
    }

    public int sensorToNode(String sensorId) {
        if (!sensorToNode.containsKey(sensorId)) {
            sensorToNode(sensorId, nextNodeId());
        }
        return sensorToNode.get(sensorId);
    }

    public String nodeToSensor(int nodeId) {
        return nodeToSensor.get(nodeId);
    }

    private int nextNodeId() {
        int temp = nextNodeId;
        nextNodeId++;
        return temp;
    }

    public boolean domainContains(String sensorId) {
        return sensorToNode.containsKey(sensorId);
    }

    public boolean imageContains(String sensorId) {
        return domainContains(sensorId);
    }

    public boolean domainContains(int nodeId) {
        return nodeToSensor.containsKey(nodeId);
    }

    public boolean imageContains(int nodeId) {
        return domainContains(nodeId);
    }
}
