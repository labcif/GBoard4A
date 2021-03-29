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
	public this(AnalysisData data)
	{
		super(data);
	}

	///
	public override string toString() const
	{
		return data.serializeToJsonPretty!();
	}
}
