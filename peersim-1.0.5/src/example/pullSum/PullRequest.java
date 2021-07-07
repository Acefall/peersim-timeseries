package example.pullSum;

import messagePassing.Message;
import peersim.core.Node;

public class PullRequest extends Message {
    public PullRequest(Node sender, Node receiver, int protocolID) {
        super(sender, receiver, protocolID);
    }
}
