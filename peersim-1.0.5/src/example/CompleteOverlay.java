package example;

import peersim.core.CommonState;
import peersim.core.Network;
import peersim.core.Node;
import peersim.core.Protocol;


/**
 * Provides a complete graph. Every node is connected to every other node.
 * A node is also connected to it self.
 * */
public class CompleteOverlay implements Protocol, RandomLinkable {
    public CompleteOverlay(String prefix){}

    @Override
    public void onKill() {

    }

    @Override
    public int degree() {
        return Network.size();
    }

    @Override
    public Node getNeighbor(int i) {
        return Network.get(i);
    }

    @Override
    public boolean addNeighbor(Node neighbour) {
        return false;
    }

    @Override
    public boolean contains(Node neighbor) {
        return true;
    }

    @Override
    public void pack() {

    }

    @Override
    public Object clone() {
        try {
            return super.clone();
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public Node getRandomNeighbor() {
        return getNeighbor(CommonState.r.nextInt(degree()));
    }
}
