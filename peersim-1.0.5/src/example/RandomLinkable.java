package example;

import peersim.core.Linkable;
import peersim.core.Node;

public interface RandomLinkable extends Linkable {
    public Node getRandomNeighbor();
}
