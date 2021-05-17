module gboardforensics.reporters.json;

import asdf.serialization;

import gboardforensics.reporters;
import gboardforensics.analysis;

/**
 * Represents an analysis result reporter for JSON format
 */
class JsonReporter : Reporter
{
	///
	@safe pure nothrow
	public this(AnalysisData data)
	{
		super(data);
	}

	///
	pure
	public override string toString() const
	{
		return data.serializeToJsonPretty!();
	}
}

///
pure
unittest
{
	AnalysisData data;
	data.path = "foobar";

	auto reporter = new JsonReporter(data);
	assert(reporter.toString() == "{\n\t\"path\": \"foobar\"\n}");
}
