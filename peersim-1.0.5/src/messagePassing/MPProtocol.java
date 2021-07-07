// Author: Alexander Weinmann uni@aweinmann.de
package messagePassing;

import java.util.Iterator;

public interface MPProtocol {
    Iterator<Message> getOutBoundMessages();

    Iterator<Message> getInBoundMessages();

    void putInboundMessage(Message m);
}
