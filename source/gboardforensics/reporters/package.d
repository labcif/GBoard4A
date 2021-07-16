/**
 * Package representing the output reporters
 *
 * Authors: João Lourenço, Luís Ferreira
 * Copyright: João Lourenço (c) 2021
 *            Luís Ferreira (c) 2021
 * License: GPL-3.0
 */
module gboardforensics.reporters;

import gboardforensics.analysis;

public {
	import gboardforensics.reporters.json;
	import gboardforensics.reporters.html;
}

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
	@safe pure nothrow
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
