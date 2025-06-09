# 🧊 Detection System for Preventing Tissue Damage in Cryotherapy  
### 📍 Bachelor’s Thesis – UPC-EEBE (Universitat Politècnica de Catalunya – Escola d’Enginyeria de Barcelona Est)

This repository contains the experimental datasets, signal analysis scripts, and result visualizations developed for the Bachelor's Thesis **"Detection System for Preventing Tissue Damage in Cryotherapy through Temperature and Capacitance Monitoring"** - UPC/EEBE.

The system was designed and validated to detect the onset of freezing in biological tissues during cryotherapy, using a combination of temperature and capacitive sensing.

---

## 📖 Abstract

Cryolipolysis is a widely used technique for aesthetic purposes that targets adipose tissue through controlled cooling. However, if the cooling is not properly regulated, it can lead to irreversible tissue damage.
This thesis proposes a detection system that monitors both **temperature** and **capacitance** in real-time to identify the **onset of freezing** and anticipate the **exothermic peak** characteristic of phase change.

The detection algorithm is based on **Standard deviation thresholding** to detect signal stabilization

The system was validated through a series of controlled freezing experiments on fluid-mimicking samples using a thermistor and a parallel-plate capacitive sensor.

---



## 🧪 Key Components

- **Temperature monitoring** using thermistors (NTC)
- **Capacitance sensing** with custom-designed parallel-plate capacitors
- **MATLAB signal processing**: smoothing, gradient analysis, peak/trough detection
- **Freezing point detection algorithms**:
  - Standard deviation thresholding of the capacitance signal

---

## 📊 Results

The detection system was capable of identifying the onset of freezing consistently across multiple trials and distances. Capacitance changes were shown to correlate with temperature drops and phase transitions, providing a reliable early indicator of ice formation.

---

## 🧰 Tools Used

- MATLAB (R2023a)
- Arduino & custom data logger
- Thermistors & parallel-plate capacitive sensors
- Peltier cells for controlled freezing
- Heat sink and power supply
- Excel / Origin for supplementary analysis

---

## 📎 Thesis

📄 [Final Thesis PDF – Report_And_Annex_Vol_I_Sole_Coves_Nicolau.pdf](https://github.com/NicolauSoleCoves/Pre-Freeze-Capacitance-Detection-System/blob/main/THESIS_Report_Annexes_Sole_Coves_Nicolau.pdf)  
🎓 Supervisor: [Noelia Vaquero Gallardo] (https://futur.upc.edu/NoeliaVaqueroGallardo)  
📍 UPC – Escola d’Enginyeria de Barcelona Est (EEBE)

---

## 📜 License

This repository and its contents are licensed under a Creative Commons license and may not be used for commercial purposes.

---

## 🤝 Acknowledgments

Special thanks to the Biomedical Engineering and Industrial Electronics departments at UPC-EEBE, and all the collaborators who supported this project.


