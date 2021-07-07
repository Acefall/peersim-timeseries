// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import approximation.Approximation;
import approximation.ErrorStats;
import peersim.config.Configuration;
import peersim.core.CommonState;
import peersim.core.Control;
import peersim.core.Network;
import peersim.util.IncrementalStats;

import java.io.IOException;
import java.nio.file.*;

/**
 * Writes the inputs of all nodes for all rounds to a log file.
 */

public class SummaryLogger implements Control {
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
    private final String gtLogfile = "/groundTruths.csv";
    private final String mseLogfile = "/mse.csv";
    private final ErrorStats errorStats = new ErrorStats();
    private final IncrementalStats gtStats = new IncrementalStats();

    private final double[][] buffer;


    public SummaryLogger(String name) {
        protocolID = Configuration.getPid(name + "." + PAR_PROT);

        bufferSize = Configuration.getInt(name + "." + PAR_BUFFER_SIZE, 1);
        buffer = new double[bufferSize][2];

        outputDir = Configuration.getString(PAR_OUTPUT_DIR);
        Path path = Paths.get(outputDir + gtLogfile);
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

        path = Paths.get(outputDir + mseLogfile);
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

    public boolean execute() {
        errorStats.reset();
        gtStats.reset();
        // Calculate gt and mse and write to buffer
        for (int i = 0; i < Network.size(); i++) {
            TSProtocol protocolInput = (TSProtocol) Network.get(i).getProtocol(protocolID);
            gtStats.add(protocolInput.getInput());
            Approximation protocolApprox = (Approximation) Network.get(i).getProtocol(protocolID);
            errorStats.add(protocolApprox.getApproximation());
        }
        double gt = gtStats.getAverage();
        buffer[CommonState.getIntTime() % bufferSize][0] = gt;
        buffer[CommonState.getIntTime() % bufferSize][1] = errorStats.getMse(gt);


        // Write to disc
        if ((CommonState.getIntTime() + 1) % bufferSize == 0 || CommonState.getIntTime() == CommonState.getEndTime() - 1) {
            StringBuilder gtString = new StringBuilder();
            StringBuilder mseString = new StringBuilder();

            // Write buffer to string
            for (int j = 0; j <= CommonState.getIntTime() % bufferSize; j++) {
                gtString.append(buffer[j][0]).append("\n");
                mseString.append(buffer[j][1]).append("\n");
            }


            try {
                Files.write(Paths.get(outputDir + gtLogfile),
                        (gtString.toString()).getBytes(), StandardOpenOption.APPEND);
            } catch (IOException e) {
                System.err.println("Could not write to file.");
            }

            try {
                Files.write(Paths.get(outputDir + mseLogfile),
                        (mseString.toString()).getBytes(), StandardOpenOption.APPEND);
            } catch (IOException e) {
                System.err.println("Could not write to file.");
            }
        }
        return false;
    }
}
