import { LightningElement } from "lwc";
import { loadStyle } from 'lightning/platformResourceLoader';
import LightningConfirmMultiline from '@salesforce/resourceUrl/LightningConfirmMultiline';
import LightningConfirm from 'lightning/confirm';
import objectOptions from '@salesforce/apex/FileUploadController.getOptions';
import delimiter from '@salesforce/apex/FileUploadController.getDelimiter';
import confirm from '@salesforce/apex/FileUploadController.preview';
import processFile from '@salesforce/apex/FileUploadController.process';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class fileUpload extends LightningElement {
  value;
  delimiter;

  get acceptedFormats() {
    return ['.csv'];
  }

  fileName = "No file uploaded yet.";
  fileData = [];
  columns = [];
  data = [];
  messgae = '';
  loading = false;
  disableUpload = true;

  options;

  connectedCallback() {
    objectOptions()
      .then((result) =>{
        this.options = result
        this.value = 'DeliveryRoute'
      })
      .catch((error)=>{
        const errorMessgae = error.body.message != ('' || undefined) ? error.body.message : error.body.pageErrors[0].message;
        this.showToastNotification(errorMessgae, 'error', 'Failed!', 'Sticky')
      })
  }  
 
  renderedCallback() {
    Promise.all([loadStyle(this, LightningConfirmMultiline)])
  }

  async handleObjectChange(event) {
    this.value = event.detail.value;
    await this.getDelimiter();

    if (this.fileData.length > 0) {
      this.parse(this.fileData)
    }
    this.disableUpload = this.data.length > 0 && this.value ? false : true
  }

  async handleFileUpload(event) {
    const files = event.detail.files;
    if (files.length > 0) {
      const file = files[0];
      this.fileName = file.name;
      await this.read(file);
    }
  }

  async read(file) {
    try {
      await this.getDelimiter();
      const result = await this.load(file);
      this.fileData = result;
      this.parse(result);
    } catch (e) {
      this.error = e;
    }
  }

  async load(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        resolve(reader.result);
      };
      reader.onerror = () => {
        reject(reader.error);
      };
      reader.readAsText(file);
    });
  }

  parse(csv) {
    const lines = csv.split(/\r\n|\n/);
    const headers = lines[0].split(this.delimiter);
    this.columns = headers.map((header) => {
      return { label: header, fieldName: header };
    });

    const data = [];
    const routes = new Set();
    lines.forEach((line, i) => {
      if (i === 0 || line === '' || line === undefined) return;
      const obj = {};
      const currentline = line.split(this.delimiter);
      for (let j = 0; j < headers.length; j++) {
        obj[headers[j]] = currentline[j];
      }
      data.push(obj);
      routes.add(obj.Name);
    });
    this.data = data;
    this.disableUpload = this.value == undefined ? true : false;
  }

  async getDelimiter() {
    await delimiter({ fileReference : this.value })
        .then(result => {
          this.delimiter = result;
        })
        .catch(error => {
            console.error(error)
        });
  }

  async handleConfirmClick() {
    await confirm({ fileReference: this.value, objectData: this.data })
      .then((result) => {
        this.messgae = result;
      })
      .catch((error) => {
        const errorMessgae = error.body.message != ('' || undefined) ? error.body.message : error.body.pageErrors[0].message;
        this.showToastNotification(errorMessgae, 'error', 'Failed!', 'Sticky')
      })
  
      if(this.messgae) {
        const result = await LightningConfirm.open({ message: this.messgae, variant: 'header', label: 'Confirm', theme: 'info' });
        if (result) {
          this.handleUpload()
        }
      }
  }

  handleUpload() {
    this.loading = true;
    processFile({ fileReference: this.value, objectData: this.data })
      .then(() => {
        this.loading = false;
        this.showToastNotification('File uploaded successfully.', 'success', 'Success!', 'dismissable')
        this.handleClear();
      })
      .catch((error) => {
        this.loading = false;
        const errorMessgae = error.body.message != ('' || undefined) ? error.body.message : error.body.pageErrors[0].message;
        this.showToastNotification(errorMessgae, 'error', 'Failed!', 'Sticky')
      });
  }

  handleClear() {
    this.fileName = "No file uploaded yet.";
    this.fileData = [];
    this.columns = [];
    this.data = [];
    this.messgae = '';
    this.disableUpload = true
  }

  showToastNotification(msg, variant, title, mode) {
    this.dispatchEvent(new ShowToastEvent({ title: title, message: msg, variant: variant, mode: mode }));
  }
}