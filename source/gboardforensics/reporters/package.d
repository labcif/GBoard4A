module gboardforensics.reporters;

import gboardforensics.analysis;

/**
 * Represents an analysis result reporter
 */
abstract class Reporter
{
	/**
	 * Constructs a reporter with the given analysis data
	 *
	 * Params:
	 *   data = analysis data to be reported
	 */
	public this(AnalysisData data)
	{
		this.data = data;
	}

	/**
	 * Converts to a string representation of the report data
	 *
	 * Returns: string representation of the report data
	 */
	public abstract override string toString() const;

	/// analysis data to be reported
	protected AnalysisData data;
}
