// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import peersim.config.Configuration;
import peersim.core.CommonState;
import peersim.core.Control;
import peersim.core.Network;

import java.io.IOException;
import java.nio.file.*;

/**
 * Writes the inputs of all nodes for all rounds to a log file.
 */

public class InputLogger implements Control {
    private static final String PAR_PROT = "protocol";

    /**
     * Parameter that defines how many rounds should be buffered.
     * 1 means that every round the output is written to disc in every round.
     * 100 means that every 100 rounds the output is written to disc.
     * Defaults to 1.
     */
    private static final String PAR_BUFFER_SIZE = "bufferSize";
    private static final String PAR_OUTPUT_DIR = "outputDir";


    private final int protocolID;
    private final String outputDir;
    private final int bufferSize;
    private final String inputsLogfile = "/inputs.csv";

    private final double[][] buffer;


    public InputLogger(String name) {
        protocolID = Configuration.getPid(name + "." + PAR_PROT);

        bufferSize = Configuration.getInt(name + "." + PAR_BUFFER_SIZE, 1);
        buffer = new double[bufferSize][Network.size()];

        outputDir = Configuration.getString(PAR_OUTPUT_DIR);
        Path path = Paths.get(outputDir + inputsLogfile);
        try {
            Files.createFile(path);
        } catch (FileAlreadyExistsException ex) {
            System.err.println("File already exists. Truncating.");
            try {
                Files.write(path, new byte[0], StandardOpenOption.TRUNCATE_EXISTING);
            } catch (IOException e) {
                System.err.println("Could not truncate the file");
            }
        } catch (IOException e) {
            System.err.println("Could not create the file.");
        }
    }

    private void writeToBuffer() {
        for (int i = 0; i < Network.size(); i++) {
            TSProtocol protocol = (TSProtocol) Network.get(i).getProtocol(protocolID);
            buffer[CommonState.getIntTime() % bufferSize][i] = protocol.getInput();
        }
    }

    private void writeToDisc() {
        StringBuilder valuesString = new StringBuilder();
        // Write buffer to string
        for (int j = 0; j <= CommonState.getIntTime() % bufferSize; j++) {
            for (int i = 0; i < Network.size(); i++) {
                valuesString.append(buffer[j][i]).append(",");
            }
            valuesString.append("\n");
        }

        try {
            Files.write(Paths.get(outputDir + inputsLogfile),
                    (valuesString.toString()).getBytes(), StandardOpenOption.APPEND);
        } catch (IOException e) {
            System.err.println("Could not write to file.");
        }
    }

    public boolean execute() {
        writeToBuffer();
        if ((CommonState.getIntTime() + 1) % bufferSize == 0 || CommonState.getIntTime() == CommonState.getEndTime() - 1) {
            writeToDisc();
        }
        return false;
    }
}
