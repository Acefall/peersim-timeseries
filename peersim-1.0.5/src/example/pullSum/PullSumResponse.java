// Author: Alexander Weinmann uni@aweinmann.de
package example.pullSum;

import messagePassing.Message;
import peersim.core.Node;

/**
 * Response sent by MassConservationPull in response to a pull request.
 */
public class PullSumResponse extends Message {
    private final double s;
    private final double w;

    public PullSumResponse(Node sender, Node receiver, int protocolID, double s, double w) {
        super(sender, receiver, protocolID);
        this.w = w;
        this.s = s;
    }

    public double getW() {
        return w;
    }

    public double getS() {
        return s;
    }
}
