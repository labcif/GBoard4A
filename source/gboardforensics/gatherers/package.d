module gboardforensics.gatherers;

/**
 * This represents an information gatherer. Any class implementing this interface
 * should gather information from a data source.
 */
interface IGatherer
{
	/**
	 * Performs the information gathering operation
	 */
	void gather();
}
