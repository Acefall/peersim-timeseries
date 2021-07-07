package example;

import messagePassing.MPProtocol;
import messagePassing.Message;
import messagePassing.MessagePassing;
import timeseries.TSProtocol;

import java.util.Iterator;

/**
 * Basic capabilities of a Time Series aggregation protocol.
 */

public abstract class AggregationProtocol implements MPProtocol, TSProtocol {
    private double input;
    public double getInput() {
        return input;
    }
    public void setInput(double input) {
        this.input = input;
    }


    protected MessagePassing messagePassing = new MessagePassing();
    @Override
    public Iterator<Message> getOutBoundMessages() {
        return messagePassing.getOutBoundMessages();
    }

    @Override
    public Iterator<Message> getInBoundMessages() {
        return messagePassing.getInBoundMessages();
    }

    @Override
    public void putInboundMessage(Message m) {
        messagePassing.putInboundMessage(m);
    }
}
