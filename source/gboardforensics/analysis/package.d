module gboardforensics.analysis;

import gboardforensics.gatherers;
import gboardforensics.models;
import gboardforensics.utils.serialization;

import std.json;
import std.exception;

import asdf : serdeIgnoreDefault;

public {
	import gboardforensics.analysis.datadir;
	import gboardforensics.analysis.dir;
	import gboardforensics.analysis.file;
}

/**
 * Database types
 */
enum DB : string
{
	PersonalDictionary = "PersonalDictionary.db",
	Trainingcache2 = "trainingcache2.db",
	Clipboard = "gboard_clipboard.db",
	ExpressionHistory = "expression-history.db"
}

/**
 * Database version
 */
enum DBVERSION
{
	Trainingcache2,
}

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
		else if (ti is typeid(TrainingCacheGatherer)) add(cast(TrainingCacheGatherer) gatherer);
		else if (ti is typeid(ClipboardGatherer)) add(cast(ClipboardGatherer) gatherer);
		else if (ti is typeid(ExpressionHistoryGatherer)) add(cast(ExpressionHistoryGatherer) gatherer);
		else if (ti is typeid(TranslateCacheGatherer)) add(cast(TranslateCacheGatherer) gatherer);
		else throw new FailedAnalysisException("Unknown analysis gatherer!");
	}

	/// ditto
	void add(DictionaryGatherer gatherer)
	{
		this.dictionaries ~= gatherer.dictionary;
	}

	/// ditto
	void add(TrainingCacheGatherer gatherer)
	{
		this.trainingcache ~= gatherer.trainingcache;
	}

	/// ditto
	void add(ClipboardGatherer gatherer)
	{
		this.clipboard ~= gatherer.clipboard;
	}

	void add(ExpressionHistoryGatherer gather)
	{
		this.expressionHistory ~= gather.expressionHistory;
	}

	void add(TranslateCacheGatherer gatherer)
	{
		this.translateCache ~= gatherer.translateCache;
	}

	auto opOpAssign(string op, T : AnalysisData)(T value)
		if (op == "~")
	{
		this.dictionaries ~= value.dictionaries;
		this.trainingcache ~= value.trainingcache;
		this.clipboard ~= value.clipboard;
		this.translateCache ~= value.translateCache;
		return this;
	}

	/**
	 * Calculates the number of total items inside a anlysis data
	 *
	 * Returns: number of total items
	 */
	size_t countItems() const
	{
		return dictionaries.countItems()
			+ trainingcache.countItems()
			+ clipboard.countItems()
			+ expressionHistory.countItems()
			+ translateCache.countItems();
	}

	/// analysis path
	@serdeIgnoreDefault string rootPath;

	/// found dictionaries
	SerializableArray!(const(Dictionary)) dictionaries;
	/// found training caches
	SerializableArray!(const(TrainingCache)) trainingcache;
	/// found clipboard
	SerializableArray!(const(Clipboard)) clipboard;
	/// found expression histories
	SerializableArray!(const(ExpressionHistory)) expressionHistory;
	/// found translate caches
	SerializableArray!(const(TranslateCache)) translateCache;
}
