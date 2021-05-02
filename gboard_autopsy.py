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

from java.util.logging import Level

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

    GBOARD_DICTIONARY_ARTIFACT = 'GBOARD_DICTIONARY_OBJECT'
    GBOARD_DICTIONARY_WORD_ATTRIBUTE = 'GBOARD_DICTIONARY_WORD_OBJECT'
    GBOARD_DICTIONARY_SHORTCUT_ATTRIBUTE = 'GBOARD_DICTIONARY_SHORTCUT_OBJECT'
    GBOARD_DICTIONARY_LOCALE_ATTRIBUTE = 'GBOARD_DICTIONARY_LOCALE_OBJECT'

    GBOARD_PACKAGE_NAME = 'com.google.android.inputmethod.latin'

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
        exe_ext = '.exe' if os.name == 'nt' else ''
        self.path_to_exe = os.path.join(module_path, 'gboard-forensics' + exe_ext)

        if not os.path.exists(self.path_to_exe):
            raise IngestModuleException('Executable file not found!')

        try:
            current_case = Case.getCurrentCaseThrows()

            # create artifacts
            self.dictionary_art_type = self.createCustomArtifactType(current_case, self.GBOARD_DICTIONARY_ARTIFACT, 'Gboard Dictionary')

            # clipboard attributes
            self.clipboard_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_CLIPBOARD_ATTRIBUTE, 'Gboard Clipboard')

            # dictionary attributes
            self.dictionary_word_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_WORD_ATTRIBUTE, 'Word')
            self.dictionary_shortcut_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_SHORTCUT_ATTRIBUTE, 'Shortcut')
            self.dictionary_locale_attr_type = self.createCustomAttributeType(current_case, self.GBOARD_DICTIONARY_LOCALE_ATTRIBUTE, 'Locale')

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

        files = file_manager.findFiles(data_source, '%', self.GBOARD_PACKAGE_NAME + '/files/clipboard_image/')
        for file in files:
            self.publish_analysis_artifact(blackboard, file, BlackboardArtifact.ARTIFACT_TYPE.TSK_CLIPBOARD_CONTENT, [
                    (self.clipboard_attr_type, str(True))
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
            '-d', input_dir,
        ]

    def get_input_dir(self, data_source, file_manager):
        files = file_manager.findFiles(data_source, "%" + self.GBOARD_PACKAGE_NAME + "%")

        for file in files:
            if file.isFile():
                path = file.getLocalAbsPath()
                if not path:
                    continue

                return self.find_first_folder(path, self.GBOARD_PACKAGE_NAME)

        raise IngestModuleException('Folder ' + self.GBOARD_PACKAGE_NAME + ' not found in ' + data_source.getName() + ' data source!')

    def find_first_folder(self, path, folder):
        normalized_path = os.path.normpath(path)
        splitted_path = normalized_path.split(os.path.sep)

        for idx, dir in enumerate(splitted_path):
            if dir == folder:
                return os.path.sep.join(splitted_path[:idx+1])

        # Not found
        return None

    def report_analysis(self, input_dir, data_source, blackboard, file_manager, analysis_output):
        for dictionary in analysis_output['dictionaries']:
            file = self.get_common_sufix_file(data_source, file_manager, input_dir, dictionary['path'])
            for entry in dictionary['entries']:
                self.publish_analysis_artifact(blackboard, file, self.dictionary_art_type, [
                    (self.dictionary_word_attr_type, entry['word']),
                    (self.dictionary_shortcut_attr_type, entry['shortcut']),
                    (self.dictionary_locale_attr_type, entry['locale'])
                ])

    def get_common_sufix_file(self, data_source, file_manager, common_path, full_path):
        if not common_path.endswith(os.path.sep):
            sanitized_path = common_path + os.path.sep
        else:
            sanitized_path = common_path

        rel_path = full_path.split(sanitized_path)
        if len(rel_path) > 1:
            full_gboard_path = os.path.join(self.GBOARD_PACKAGE_NAME, os.path.dirname(rel_path[1]))
            files = file_manager.findFiles(data_source, os.path.basename(rel_path[1]), full_gboard_path)
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
        except Blackboard.BlackboardException as ex:
            self.log(Level.SEVERE, "Error indexing artifact " + artifact.getDisplayName())
