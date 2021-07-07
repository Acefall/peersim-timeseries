// Author: Alexander Weinmann uni@aweinmann.de
package approximation;

/**
 * Approximator that uses two values s and w to approximate the mean.
 * This class is extended by a group of aggregation algorithms.
 */
public abstract class SWApproximation extends SNApproximation implements Approximation {

    public double getW() {
        return getN();
    }

    public void setW(double n) {
        setN(n);
    }

    /**
     * Compute the approximation by S/W.
     *
     * @return S/W
     */
    @Override
    public double getApproximation() {
        return getS() / getW();
    }

}
