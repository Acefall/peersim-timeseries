// Author: Alexander Weinmann uni@aweinmann.de
package messagePassing;

import peersim.core.Node;

/**
 * Message that is sent from a protocol on the sending node to a protocol on the receiving node
 */
public abstract class Message {
    private final MPProtocol senderProtocol;
    private final MPProtocol receiverProtocol;
    private final Node sender;
    private final Node receiver;

    public Message(Node sender, Node receiver, int protocolID) {
        this.sender = sender;
        this.receiver = receiver;
        senderProtocol = (MPProtocol) sender.getProtocol(protocolID);
        receiverProtocol = (MPProtocol) receiver.getProtocol(protocolID);
    }

    public MPProtocol getSenderProtocol() {
        return senderProtocol;
    }

    public MPProtocol getReceiverProtocol() {
        return receiverProtocol;
    }

    public Node getSender() {
        return sender;
    }

    public Node getReceiver() {
        return receiver;
    }
}
