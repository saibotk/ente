import { runningInBrowser } from 'utils/common/utilFunctions';
import downloadManager from './downloadManager';
import { file } from './fileService';

class ExportService {
    ElectronAPIs: any = runningInBrowser() && window['ElectronAPIs'];
    async exportFiles(files: file[]) {
        const dir = await this.ElectronAPIs.selectDirectory();
        const exportedFiles: Set<string> = await this.ElectronAPIs.getExportedFiles(
            dir
        );
        for (let file of files) {
            const uid = `${file.id}_${file.metadata.title}`;
            if (!exportedFiles.has(uid)) {
                await this.downloadAndSave(file, `${dir}/${uid}`);
                this.ElectronAPIs.updateExportRecord(dir, uid);
            }
        }
    }

    async downloadAndSave(file: file, path) {
        console.log(this.ElectronAPIs);

        const fileStream = await downloadManager.downloadFile(file);

        this.ElectronAPIs.saveToDisk(path, fileStream);
    }
}
export default new ExportService();
