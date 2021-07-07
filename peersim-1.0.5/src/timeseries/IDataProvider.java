// Author: Alexander Weinmann uni@aweinmann.de
package timeseries;

import java.time.LocalDateTime;
import java.util.HashMap;

/**
 * Provides a mapping from node ids to measured values.
 */

public interface IDataProvider {
    HashMap<Integer, Double> nodeValuesAt(LocalDateTime t);
}
