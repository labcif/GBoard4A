import inspect
import json
import os
import subprocess

from org.sleuthkit.autopsy.casemodule import Case
from org.sleuthkit.autopsy.casemodule import NoCurrentCaseException
from org.sleuthkit.autopsy.coreutils import Logger
from org.sleuthkit.autopsy.ingest import IngestModuleFactoryAdapter
from org.sleuthkit.autopsy.ingest import DataSourceIngestModule
from org.sleuthkit.autopsy.ingest import IngestModule
from org.sleuthkit.datamodel import TskCoreException, TskDataException
from org.sleuthkit.autopsy.casemodule.services import Blackboard
from org.sleuthkit.autopsy.ingest.IngestModule import IngestModuleException
from org.sleuthkit.datamodel import BlackboardAttribute
from org.sleuthkit.datamodel import BlackboardArtifact
from org.sleuthkit.autopsy.report import GeneralReportModuleAdapter
from org.sleuthkit.autopsy.report.ReportProgressPanel import ReportStatus

from java.util.logging import Level
from java.lang import System

GBOARD_PACKAGE_NAME = 'com.google.android.inputmethod.latin'

def find_first_folder(path, folder):
    normalized_path = os.path.normpath(path)
    splitted_path = normalized_path.split(os.path.sep)

    for idx, dir in enumerate(splitted_path):
        if dir == folder:
            return os.path.sep.join(splitted_path[:idx+1])

    # Not found
    return None

class GboardDataSourceIngestModuleFactory(IngestModuleFactoryAdapter):

    moduleName = "GBoard4A"

    def getModuleDisplayName(self):
        return self.moduleName

    def getModuleDescription(self):
        return "Extracts Android GBoard app data."

    def getModuleVersionNumber(self):
        return "1.0"

    def isDataSourceIngestModuleFactory(self):
        return True

    def createDataSourceIngestModule(self, ingest_options):
        return GboardDataSourceIngestModule()

class GboardDataSourceIngestModule(DataSourceIngestModule):

    _logger = Logger.getLogger(GboardDataSourceIngestModuleFactory.moduleName)

    GBOARD_CLIPBOARD_ATTRIBUTE = 'GBOARD_CLIPBOARD_OBJECT'
    GBOARD_CLIPBOARD_HTML_TEXT_ATTRIBUTE = 'GBOARD_CLIPBOARD_HTML_TEXT_OBJECT'

    GBOARD_EMOJIS_ARTIFACT = 'GBOARD_EMOJIS_OBJECT'
    GBOARD_EMOTICONS_ARTIFACT = 'GBOARD_EMOTICONS_OBJECT'

    GBOARD_EXPRESSION_SHARES_ATTRIBUTE = 'GBOARD_EXPRESSION_SHARES_OBJECT'
    GBOARD_EXPRESSION_EMOJI_ATTRIBUTE = 'GBOARD_EXPRESSION_EMOJI_OBJECT'
    GBOARD_EXPRESSION_BASE_EMOJI_ATTRIBUTE = 'GBOARD_EXPRESSION_BASE_EMOJI_OBJECT'
    GBOARD_EXPRESSION_EMOTICON_ATTRIBUTE = 'GBOARD_EXPRESSION_EMOTICON_OBJECT'

    GBOARD_DICTIONARY_ARTIFACT = 'GBOARD_DICTIONARY_OBJECT'
    GBOARD_DICTIONARY_WORD_ATTRIBUTE = 'GBOARD_DICTIONARY_WORD_OBJECT'
    GBOARD_DICTIONARY_SHORTCUT_ATTRIBUTE = 'GBOARD_DICTIONARY_SHORTCUT_OBJECT'
    GBOARD_DICTIONARY_LOCALE_ATTRIBUTE = 'GBOARD_DICTIONARY_LOCALE_OBJECT'

    GBOARD_TRANSLATE_ARTIFACT = 'GBOARD_TRANSLATE_OBJECT'
    GBOARD_TRANSLATE_ORIGINAL_ATTRIBUTE = 'GBOARD_TRANSLATE_ORIGINAL_OBJECT'
    GBOARD_TRANSLATE_TRANSLATED_ATTRIBUTE = 'GBOARD_TRANSLATE_TRANSLATED_OBJECT'
    GBOARD_TRANSLATE_FROM_ATTRIBUTE = 'GBOARD_TRANSLATE_FROM_OBJECT'
    GBOARD_TRANSLATE_TO_ATTRIBUTE = 'GBOARD_TRANSLATE_TO_OBJECT'
    GBOARD_TRANSLATE_URL_ATTRIBUTE = 'GBOARD_TRANSLATE_URL_OBJECT'

    GBOARD_TC_HISTORY_TIMELINE_ARTIFACT = 'GBOARD_TC_HISTORY_TIMELINE_OBJECT'
    GBOARD_TC_RAW_ASSEMBLED_TIMELINE_ARTIFACT = 'GBOARD_TC_RAW_ASSEMBLED_TIMELINE_OBJECT'
    GBOARD_TC_PROCESSED_HISTORY_ARTIFACT = 'GBOARD_TC_PROCESSED_HISTORY_OBJECT'

    GBOARD_TC_DELETE_FLAG_ATTRIBUTE = 'GBOARD_TC_DELETE_FLAG_OBJECT'

    def log(self, level, msg):
        self._logger.logp(level, self.__class__.__name__, inspect.stack()[1][3], msg)

    def __init__(self):
        self.context = None

    def startUp(self, context):
        """Where module setup and configuration is done

        Args:
            context (IngestJobContext): Context of the ingest module
        """

        self.log(Level.INFO, "GBoard Data Source Ingest Module is starting up...")

        # setup the current context
        self.context = context

        # check if executable exists
        module_path = os.path.dirname(os.path.abspath(__file__))
        exe_ext = '.exe' if 'win' in System.getProperty("os.name").encode('ascii','ignore').lower() else ''
        self.path_to_exe = os.path.join(module_path, 'gboard-forensics' + exe_ext)

        if not os.path.exists(self.path_to_exe):
            raise IngestModuleException('Executable file not found!')

        try:
            current_case = Case.getCurrentCaseThrows()

            # create artifacts
            self.dictionary_art_type = self.createCustomArtifactType(current_case, self.GBOARD_DICTIONARY_ARTIFACT, 'Gboard Dictionary')
            self.tc_history_timeline_art_type = self.createCustomArtifactType(current_case, self.GBOARD_TC_HISTORY_TIMELINE_ARTIFACT, 'Gboard History Timeline')
            self.tc_raw_assembled_timeline_art_type = self.createCustomArtifactType(current_case, self.GBOARD_TC_RAW_ASSEMBLED_TIMELINE_ARTIFACT, 'Gboard Assembled Timeline')
            self.tc_processed_history_art_type = self.createCustomArtifactType(current_case, self.GBOARD_TC_PROCESSED_HISTORY_ARTIFACT, 'Gboard Processed History')
            self.emojis_art_type = self.createCustomArtifactType(current_case, self.GBOARD_EMOJIS_ARTIFACT, 'Gboard Expression History: Emojis')
            self.emoticons_art_type = self.createCustomArtifactType(current_case, self.GBOARD_EMOTICONS_ARTIFACT, 'Gboard Expression History: Emoticons')
            self.translate_art_type = self.createCustomArtifactType(current_case, self.GBOARD_TRANSLATE_ARTIFACT, 'Gboard Translate Cache')

            # emojis and emoticons attributes
            self.expression_shares_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_EXPRESSION_SHARES_ATTRIBUTE, 'Shares')
            self.expression_emoji_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_EXPRESSION_EMOJI_ATTRIBUTE, 'Emoji')
            self.expression_base_emoji_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_EXPRESSION_BASE_EMOJI_ATTRIBUTE, 'Base Emoji')
            self.expression_emoticon_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_EXPRESSION_EMOTICON_ATTRIBUTE, 'Emoticon')

            # training cache attributes
            self.tc_delete_flag_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TC_DELETE_FLAG_ATTRIBUTE, 'Deleted?')

            # clipboard attributes
            self.clipboard_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_CLIPBOARD_ATTRIBUTE, 'Gboard Clipboard')
            self.clipboard_html_text_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_CLIPBOARD_HTML_TEXT_ATTRIBUTE, 'HTML Text')

            # dictionary attributes
            self.dictionary_word_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_WORD_ATTRIBUTE, 'Word')
            self.dictionary_shortcut_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_SHORTCUT_ATTRIBUTE, 'Shortcut')
            self.dictionary_locale_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_LOCALE_ATTRIBUTE, 'Locale')

            # translation cache attributes
            self.translate_original_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TRANSLATE_ORIGINAL_ATTRIBUTE, 'Original Text')
            self.translate_translated_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TRANSLATE_TRANSLATED_ATTRIBUTE, 'Translated Text')
            self.translate_from_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TRANSLATE_FROM_ATTRIBUTE, 'From Language')
            self.translate_to_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TRANSLATE_TO_ATTRIBUTE, 'To Language')
            self.translate_url_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_TRANSLATE_URL_ATTRIBUTE, 'Request URL')

        except NoCurrentCaseException as ex:
            self.log(Level.WARNING, "No case currently open. " + ex)

    def process(self, data_source, progress_bar):
        """Where the analysis is done

        Args:
            data_source (Content): autopsy case data source
            progressBar (DataSourceIngestModuleProgress): progress bar related to this analysis
        """

        progress_bar.switchToIndeterminate()
        self.log(Level.INFO, "GBoard Data Source Ingest Module is analysing...")

        try:
            current_case = Case.getCurrentCaseThrows()
            services = current_case.getServices()

            blackboard = services.getBlackboard()
            file_manager = services.getFileManager()

            input_dir = self.get_input_dir(data_source, file_manager)
            # Run GBoard analysis tool
            analysis_output = self.run_analyzer(input_dir)
            # Report analysis to Autopsy Blackboard
            self.report_analysis(input_dir, data_source, blackboard, file_manager, analysis_output)
            # Report clipboard analysis to Autopsy Blackboard
            # TODO: This should be inside the tool aswell
            self.analyze_clipboard(blackboard, data_source, file_manager)

            return IngestModule.ProcessResult.OK

        except NoCurrentCaseException as ex:
            self.log(Level.WARNING, "No case currently open. " + ex.toString())

    def createCustomArtifactType(self, current_case, art_type_name, art_desc):
        """Create a custom Blackboard artifact type

        Args:
            current_case (Case): current autopsy case to be analyzed
            art_type_name (str): Unique string representing the artifact
            art_desc (str): Artifact description

        Returns:
            A BlackboardArtifact.Type instance created by the sleuthkit case.
        """

        sk_case = current_case.getSleuthkitCase()

        try:
            sk_case.addBlackboardArtifactType(art_type_name, art_desc)
        except (TskCoreException, TskDataException) as ex:
            self.log(Level.SEVERE, 'Error creating artifact type: ' + art_type_name)
            self.log(Level.SEVERE, ex.toString())

        return sk_case.getArtifactType(art_type_name)

    def createCustomAttributeType(self, current_case, attr_type_name, attr_desc):
        """Create a custom Blackboard attribute type

        Args:
            current_case (Case): current autopsy case to be analyzed
            attr_type_name (str): Unique string representing the attribute
            attr_desc (str): Attribute description

        Returns:
            A BlackboardAttribute.Type instance created by the sleuthkit case.
        """

        sk_case = current_case.getSleuthkitCase()
        try:
            sk_case.addArtifactAttributeType(attr_type_name, BlackboardAttribute.TSK_BLACKBOARD_ATTRIBUTE_VALUE_TYPE.STRING, attr_desc)
        except (TskCoreException, TskDataException) as ex:
            self.log(Level.SEVERE, 'Error creating attribute type: ' + attr_type_name)
            self.log(Level.SEVERE, ex.toString())

        return sk_case.getAttributeType(attr_type_name)

    def analyze_clipboard(self, blackboard, data_source, file_manager):
        """Analyze gboard clipboard content and publish to blackboard

        Args:
            blackboard (Blackboard): blackboard artifact indexer
            data_source (Content): autopsy case data source
            file_manager (FileManager): file manager service
        """

        files = file_manager.findFiles(data_source, '%', GBOARD_PACKAGE_NAME + '/files/clipboard_image/')
        for file in files:
            timestamp = os.path.basename(os.path.splitext(file.getLocalAbsPath())[0])
            self.publish_analysis_artifact(blackboard, file, BlackboardArtifact.ARTIFACT_TYPE.TSK_CLIPBOARD_CONTENT, [
                    (self.clipboard_attr_type, str(True)),
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, long(timestamp) / 1000)
                ])

    def run_analyzer(self, input_dir):
        """Run analyzer tool with a given input directory

        Args:
            input_dir (str): Input directory

        Returns:
            A dict python object representing the JSON output reported by the
            tool.
        """

        self.log(Level.INFO, "Running analyzer on " + input_dir + " folder")

        cmd_args = self.generate_analyzer_args(input_dir)
        process = subprocess.Popen(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        cmd_out, cmd_err = process.communicate()
        if process.returncode != 0:
            raise IngestModuleException('Executable failed to execute! \nstdout:' + cmd_out + '\nstderr:' + cmd_err)

        return json.loads(cmd_out)

    def generate_analyzer_args(self, input_dir):
        return [
            self.path_to_exe,
            '-r', input_dir,
        ]

    def get_input_dir(self, data_source, file_manager):
        files = file_manager.findFiles(data_source, "%" + GBOARD_PACKAGE_NAME + "%")

        for file in files:
            if file.isFile():
                path = file.getLocalAbsPath()
                if not path:
                    continue

                return find_first_folder(path, GBOARD_PACKAGE_NAME)

        raise IngestModuleException('Folder ' + GBOARD_PACKAGE_NAME + ' not found in ' + data_source.getName() + ' data source!')

    def report_analysis(self, input_dir, data_source, blackboard, file_manager, analysis_output):
        for dictionary in analysis_output['dictionaries']:
            file = self.get_common_sufix_file(data_source, file_manager, input_dir, dictionary['path'])
            for entry in dictionary['entries']:
                self.publish_analysis_artifact(blackboard, file, self.dictionary_art_type, [
                    (self.dictionary_word_attr_type, entry['word']),
                    (self.dictionary_shortcut_attr_type, entry['shortcut']),
                    (self.dictionary_locale_attr_type, entry['locale'])
                ])

        for clipboard in analysis_output['clipboard']:
            file = self.get_common_sufix_file(data_source, file_manager, input_dir, clipboard['path'])
            for entry in clipboard['entries']:
                if entry['type'] != "DOCUMENT":
                    attr_lst = [
                        (self.clipboard_attr_type, str(True)),
                        (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, entry['timestamp'] / 1000),
                        (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_TEXT, entry['text']),
                    ]

                    if 'html' in entry:
                        attr_lst.append((self.clipboard_html_text_attr_type, entry['html'])),

                    self.publish_analysis_artifact(blackboard, file, BlackboardArtifact.ARTIFACT_TYPE.TSK_CLIPBOARD_CONTENT, attr_lst)

        for expressionhistory in analysis_output['expressionHistory']:
            file = self.get_common_sufix_file(data_source, file_manager, input_dir, expressionhistory['path'])
            for emoji in expressionhistory['emojis']:
                self.publish_analysis_artifact(blackboard, file, self.emojis_art_type, [
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, emoji['lastTimestamp'] / 1000),
                    (self.expression_emoji_attr_type, emoji['emoji']),
                    (self.expression_base_emoji_attr_type, emoji['baseEmoji']),
                    (self.expression_shares_attr_type, str(emoji['shares'])),
                ])

            for emoticon in expressionhistory['emoticons']:
                self.publish_analysis_artifact(blackboard, file, self.emoticons_art_type, [
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, emoticon['lastTimestamp'] / 1000),
                    (self.expression_emoticon_attr_type, emoticon['emoticon']),
                    (self.expression_shares_attr_type, str(emoticon['shares'])),
                ])

        for translationcache in analysis_output['translateCache']:
            for entry in translationcache['data']:
                req_file = self.get_common_sufix_file(data_source, file_manager, input_dir, entry['requestPath'])
                res_file = self.get_common_sufix_file(data_source, file_manager, input_dir, entry['responsePath'])

                attr_lst = [
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, entry['timestamp']),
                    (self.translate_original_attr_type, entry['orig']),
                    (self.translate_translated_attr_type, entry['trans']),
                    (self.translate_from_attr_type, entry['from']),
                    (self.translate_to_attr_type, entry['to']),
                    (self.translate_url_attr_type, entry['requestURL'])
                ]

                self.publish_analysis_artifact(blackboard, req_file, self.translate_art_type, attr_lst)
                self.publish_analysis_artifact(blackboard, res_file, self.translate_art_type, attr_lst)

        for trainingcache in analysis_output['trainingcache']:
            file = self.get_common_sufix_file(data_source, file_manager, input_dir, trainingcache['path'])
            # process raw histories
            for entry in trainingcache['historyTimeline']:
                self.publish_raw_history_artifact(blackboard, file, entry, self.tc_history_timeline_art_type)
            for entry in trainingcache['assembledTimeline']:
                self.publish_raw_history_artifact(blackboard, file, entry, self.tc_raw_assembled_timeline_art_type)
            # process relevant histories
            for entry in trainingcache['processedHistory']:
                self.publish_analysis_artifact(blackboard, file, self.tc_processed_history_art_type, [
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, entry['timestamp'] / 1000),
                    (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_TEXT, entry['sequence']),
                ])

    def publish_raw_history_artifact(self, blackboard, file, entry, art_type):
        self.publish_analysis_artifact(blackboard, file, art_type, [
            (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_DATETIME, entry['timestamp'] / 1000),
            (BlackboardAttribute.ATTRIBUTE_TYPE.TSK_TEXT, entry['sequence']),
            (self.tc_delete_flag_attr_type, str(entry['deleted']))
        ])

    def get_common_sufix_file(self, data_source, file_manager, common_path, full_path):
        if not common_path.endswith(os.path.sep):
            sanitized_path = common_path + os.path.sep
        else:
            sanitized_path = common_path

        rel_path = full_path.split(sanitized_path)
        if len(rel_path) > 1:
            full_gboard_path = os.path.join(GBOARD_PACKAGE_NAME, os.path.dirname(rel_path[1])).replace("\\", "/")
            files = file_manager.findFiles(data_source, os.path.basename(rel_path[1]).replace("\\", "/"), full_gboard_path)
            return files[0] if files else None
        else:
            return None

    def publish_analysis_artifact(self, blackboard, file, artifact_type, attr_list = []):
        artifact = file.newArtifact(artifact_type.getTypeID())

        blackboard_attr_list = []
        for attr_type, attr_content in attr_list:
            blackboard_attr_list.append(BlackboardAttribute(attr_type,
            GboardDataSourceIngestModuleFactory.moduleName, attr_content))

        if blackboard_attr_list:
            artifact.addAttributes(blackboard_attr_list)

        try:
            # index the artifact for keyword search
            blackboard.indexArtifact(artifact)
        except Blackboard.BlackboardException:
            self.log(Level.SEVERE, "Error indexing artifact " + artifact.getDisplayName())

class GBoardGeneralReportModule(GeneralReportModuleAdapter):
    moduleName = "GBoard General Report Module"

    _logger = Logger.getLogger(moduleName)

    def log(self, level, msg):
        self._logger.logp(level, self.__class__.__name__, inspect.stack()[1][3], msg)

    def getName(self):
        return self.moduleName

    def getDescription(self):
        return "Extracts Android GBoard app data to an HTML report"

    def getRelativeFilePath(self):
        return "report.html"

    def generate_reporter_args(self, input_dir):
        return [
            self.path_to_exe,
            '-t', 'html',
            '-r', input_dir
        ]

    def run_reporter(self, input_dir):
        """Run reporter tool with a given input directory

        Args:
            input_dir (str): Input directory
            output_file (str): Output file
        """

        self.log(Level.INFO, "Running reporter on " + input_dir + " folder")

        cmd_args = self.generate_reporter_args(input_dir)
        self.log(Level.INFO, "Command Args:" + str(cmd_args))

        process = subprocess.Popen(cmd_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        cmd_out, cmd_err = process.communicate()
        if process.returncode != 0:
            raise IngestModuleException('Executable failed to execute! \nstdout:' + cmd_out + '\nstderr:' + cmd_err)

        return cmd_out

    def get_input_dir(self, file_manager):
        files = file_manager.findFiles("%" + GBOARD_PACKAGE_NAME + "%")

        for file in files:
            if file.isFile():
                path = file.getLocalAbsPath()
                if not path:
                    continue

                return find_first_folder(path, GBOARD_PACKAGE_NAME)

        raise IngestModuleException('Folder ' + GBOARD_PACKAGE_NAME + ' not found in current case!')

    # The 'baseReportDir' object being passed in is a string with the directory that reports are being stored in.   Report should go into baseReportDir + getRelativeFilePath().
    # The 'progressBar' object is of type ReportProgressPanel.
    #   See: http://sleuthkit.org/autopsy/docs/api-docs/latest/classorg_1_1sleuthkit_1_1autopsy_1_1report_1_1_report_progress_panel.html
    def generateReport(self, baseReportDir, progressBar):

        module_path = os.path.dirname(os.path.abspath(__file__))
        exe_ext = '.exe' if os.name == 'nt' else ''
        self.path_to_exe = os.path.join(module_path, 'gboard-forensics' + exe_ext)

        self.log(Level.INFO, "Running reporter for " + baseReportDir.getReportDirectoryPath() + " folder")
        self.log(Level.INFO, "Relative file path: " + self.getRelativeFilePath())

        # Issue: https://sleuthkit.discourse.group/t/error-generting-reports-in-python/2297
        output_file = os.path.join(baseReportDir.getReportDirectoryPath(), self.getRelativeFilePath())
        progressBar.setIndeterminate(True)
        progressBar.start()

        try:
            current_case = Case.getCurrentCaseThrows()
            services = current_case.getServices()

            file_manager = services.getFileManager()

            input_dir = self.get_input_dir(file_manager)
            # Run GBoard analysis tool
            report_output = self.run_reporter(input_dir)

            report = open(output_file, 'w')
            report.write(report_output)
            report.close()

            current_case.addReport(output_file, self.moduleName, "HTML Report")
            progressBar.complete(ReportStatus.COMPLETE)

        except NoCurrentCaseException as ex:
            self.log(Level.WARNING, "No case currently open. " + ex.toString())
            progressBar.complete(ReportStatus.ERROR)
