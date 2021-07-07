// Author: Alexander Weinmann uni@aweinmann.de
package approximation;

public interface Approximation {
    /**
     * Returns the current approximation of the protocol. Used by the observer to log the results.
     *
     * @return the approximation
     */
    double getApproximation();
}
