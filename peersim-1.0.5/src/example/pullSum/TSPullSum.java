// Author: Alexander Weinmann uni@aweinmann.de
package example.pullSum;

import approximation.Approximation;
import approximation.SWApproximation;
import example.RandomLinkable;
import messagePassing.Message;
import messagePassing.MessagePassing;
import peersim.cdsim.CDProtocol;
import peersim.config.FastConfig;
import peersim.core.CommonState;
import peersim.core.Node;

import java.util.Iterator;

/**
 * Pull Sum protocol inspired by Push Sum
 * Uses conservation of mass to converge to the true mean.
 */
public class TSPullSum extends SWApproximation implements CDProtocol, Approximation {
    private final String name;
    private double oldInput;

    public TSPullSum(String prefix) {
        this.name = prefix;
    }

    @Override
    public void nextCycle(Node node, int protocolID) {
        if(CommonState.getIntTime() == 0){
            oldInput = getInput();
            setS(oldInput);
        }

        // Get a random neighbour
        int linkableID = FastConfig.getLinkable(protocolID);
        RandomLinkable linkable = (RandomLinkable) node.getProtocol(linkableID);
        Node peer = linkable.getRandomNeighbor();

        if(CommonState.getIntTime() % 2 == 0){
            messagePassing.putOutboundMessage(new PullRequest(node, peer, protocolID));
            messagePassing.putOutboundMessage(new PullRequest(node, node, protocolID));
            if (CommonState.getIntTime() != 0) {
                processResponses();
            }
        }

        if(CommonState.getIntTime() % 2 == 1){
            double d = getInput() - oldInput;
            setS(getS() + d);
            oldInput = getInput();


            processRequests(node, protocolID);
        }

    }

    private void processResponses(){
        setS(0);
        setW(0);
        Iterator<Message> messages = messagePassing.getInBoundMessages();
        while (messages.hasNext()) {
            Message message = messages.next();
            if(message instanceof PullSumResponse){
                PullSumResponse response = (PullSumResponse) message;
                setS(getS() + response.getS());
                setW(getW() + response.getW());
                messages.remove();
            }
        }
    }

    private void processRequests(Node node, int protocolID){
        // Count the number of requests in the inbox
        int numPullRequests = 0;
        Iterator<Message> messages = messagePassing.getInBoundMessages();
        while (messages.hasNext()) {
            Message message = messages.next();
            if (message instanceof PullRequest){
                numPullRequests++;
            }
        }

        // Answer the requests
        messages = messagePassing.getInBoundMessages();
        while (messages.hasNext()) {
            Message message = messages.next();
            if (message instanceof PullRequest){
                messagePassing.putOutboundMessage(new PullSumResponse(
                        node,
                        message.getSender(),
                        protocolID,
                        getS()/numPullRequests,
                        getW()/numPullRequests));
            }
            messages.remove();
        }
    }


    public Object clone() {
        TSPullSum tsPullSum = new TSPullSum(name);
        tsPullSum.messagePassing = new MessagePassing();
        tsPullSum.setW(1);
        return tsPullSum;
    }
}
