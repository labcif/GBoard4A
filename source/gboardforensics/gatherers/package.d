/**
 * Package representing all the gatherers of GBoard sources
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.gatherers;

public {
	import gboardforensics.gatherers.dictionary;
	import gboardforensics.gatherers.trainingcache;
	import gboardforensics.gatherers.clipboard;
	import gboardforensics.gatherers.expressionhistory;
	import gboardforensics.gatherers.translatecache;
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
