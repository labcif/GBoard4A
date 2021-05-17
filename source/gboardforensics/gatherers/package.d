module gboardforensics.gatherers;

public {
	import gboardforensics.gatherers.dictionary;
	import gboardforensics.gatherers.trainingcache;
	import gboardforensics.gatherers.clipboard;
}

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
