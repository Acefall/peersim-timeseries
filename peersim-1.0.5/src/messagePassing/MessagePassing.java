// Author: Alexander Weinmann uni@aweinmann.de
package messagePassing;

import java.util.HashSet;
import java.util.Iterator;

/**
 * Used by protocols using composition. Provides message passing functionality to a protocol.
 */
public class MessagePassing {
    private final HashSet<Message> inboundMessages = new HashSet<>();
    private final HashSet<Message> outboundMessages = new HashSet<>();

    public void putInboundMessage(Message m) {
        inboundMessages.add(m);
    }

    public void putOutboundMessage(Message m) {
        outboundMessages.add(m);
    }

    public Iterator<Message> getOutBoundMessages() {
        return outboundMessages.iterator();
    }

    public Iterator<Message> getInBoundMessages() {
        return inboundMessages.iterator();
    }
}
