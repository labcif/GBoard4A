module gboardforensics.analysis;

import gboardforensics.gatherers;
import gboardforensics.gatherers.dictionary;
import gboardforensics.models.dictionary;


import std.json;
import std.exception;

/**
 * This exception represents a failure on the analysis process. This exception
 * is thrown when in a running analysis any type of fatal error occurs.
 */
@safe pure
class FailedAnalysisException : Exception {
	///
	mixin basicExceptionCtors;
}

/**
 * Represents an analysis report data. This contains all the data gathered from
 * the gatherers.
 */
struct AnalysisData
{
	/**
	 * Adds information from a gatherer
	 *
	 * Params:
	 *   gatherer = information gatherer
	 */
	void add(IGatherer gatherer)
	{
		// gather the data
		gatherer.gather();

		auto ti = (cast(Object) gatherer).classinfo;

		// dynamically detect gatherer type
		if(ti is typeid(DictionaryGatherer)) add(cast(DictionaryGatherer) gatherer);
		else throw new FailedAnalysisException("Unknown analysis gatherer!");
	}

	/// ditto
	void add(DictionaryGatherer gatherer)
	{
		this.dictionaries ~= gatherer.dictionary;
	}

	/// found dictionaries
	const(Dictionary)[] dictionaries;
}
