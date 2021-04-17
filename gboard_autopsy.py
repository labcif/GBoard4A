import inspect
import os

from org.sleuthkit.autopsy.casemodule import Case
from org.sleuthkit.autopsy.casemodule import NoCurrentCaseException
from org.sleuthkit.autopsy.coreutils import Logger
from org.sleuthkit.autopsy.ingest import IngestModuleFactoryAdapter
from org.sleuthkit.autopsy.ingest import DataSourceIngestModule
from org.sleuthkit.autopsy.ingest import IngestModule
from org.sleuthkit.autopsy.ingest import IngestServices
from org.sleuthkit.datamodel.blackboardutils import ArtifactsHelper
from org.sleuthkit.datamodel import TskCoreException, TskDataException
from org.sleuthkit.autopsy.casemodule.services import Blackboard
from org.sleuthkit.autopsy.ingest.IngestModule import IngestModuleException

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

    def createDataSourceIngestModule(self, ingestOptions):
        return GboardDataSourceIngestModule()

class GboardDataSourceIngestModule(DataSourceIngestModule):

    _logger = Logger.getLogger(GboardDataSourceIngestModuleFactory.moduleName)

    GBOARD_CLIPBOARD_ARTIFACT = 'GBOARD_CLIPBOARD_OBJECT'
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
        path_to_exe = os.path.join(module_path, 'gboard-forensics' + exe_ext)

        if not os.path.exists(path_to_exe):
            raise IngestModuleException('Executable file not found!')

        try:
            current_case = Case.getCurrentCaseThrows()

            # create artifacts
            self.clipboard_type = self.createCustomArtifactType(current_case, self.GBOARD_CLIPBOARD_ARTIFACT, 'Gboard Clipboard')
        except NoCurrentCaseException as ex:
            self.log(Level.WARNING, "No case currently open. " + ex)

    def process(self, data_source, progress_bar):
        """Where the analysis is done

        Args:
        dataSource (Content): autopsy case data source
        progressBar (DataSourceIngestModuleProgress): progress bar related to this analysis
        """

        progress_bar.switchToIndeterminate()
        self.log(Level.INFO, "GBoard Data Source Ingest Module is analysing...")

        try:
            current_case = Case.getCurrentCaseThrows()
            services = current_case.getServices()

            blackboard = services.getBlackboard()
            file_manager = services.getFileManager()

            files = file_manager.findFiles('%', self.GBOARD_PACKAGE_NAME + '/files/clipboard_image')
            for file in files:
                self.log(Level.INFO, file.toString())
                artifact = file.newArtifact(self.clipboard_type.getTypeID())

                try:
                    # index the artifact for keyword search
                    blackboard.indexArtifact(artifact)
                except Blackboard.BlackboardException as ex:
                    self.log(Level.SEVERE, "Error indexing artifact " + artifact.getDisplayName())


            self.log(Level.INFO, data_source.toString())

            return IngestModule.ProcessResult.OK
        except NoCurrentCaseException as ex:
            self.log(Level.WARNING, "No case currently open. " + ex.toString())

    def createCustomArtifactType(self, current_case, art_type_name, art_desc):
        sk_case = current_case.getSleuthkitCase()

        try:
            sk_case.addBlackboardArtifactType(art_type_name, art_desc)
        except (TskCoreException, TskDataException) as ex:
            self.log(Level.INFO, 'Error creating artifact type: ' + art_type_name)
            self.log(Level.INFO, ex.toString())

        return sk_case.getArtifactType(art_type_name)
