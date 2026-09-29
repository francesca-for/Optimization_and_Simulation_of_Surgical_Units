# Optimization and Simulation for Industrial Automation — Final Project

**Course:** Optimization and Simulation for Industrial Automation (A.Y. 2024/2025)  
**Institution:** Politecnico di Torino  
**Instructors:** Prof. Alberto Tarable, Prof. Marco Ghirardi  

---

## Project Overview

This repository contains the MATLAB scripts, Simulink/SimEvents models, and technical report for the final project of the Optimization and Simulation for Industrial Automation course. 

The objective of the project is to model, simulate, and optimize the patient workflow inside a small surgical unit equipped for two types of procedures: **Appendectomy ($A$)** and **Tonsillectomy ($T$)**.

### System Architecture

Each surgical operation consists of three sequential stages:
1. **Stage 1 (Anesthesia):** Equipped with $m_1$ identical rooms. If all Stage-1 rooms are occupied upon arrival, the patient waits in an unlimited-capacity waiting room.
2. **Stage 2 (Operation):** Equipped with $m_2$ identical rooms. There is no intermediate waiting room between Stage 1 and Stage 2; if all $m_2$ rooms are busy, the patient waits inside the Stage-1 room where anesthesia was performed (blocking policy).
3. **Stage 3 (Recovery):** Equipped with $m_3$ identical rooms. Similarly, if all $m_3$ rooms are occupied, the patient waits inside their Stage-2 operating room until a recovery room becomes available.

Once recovery is completed, the patient leaves the surgical unit. Each room can host at most one patient at a time.

### Service Time Distributions

The processing time required for each stage is modeled as an exponentially distributed random variable. The mean service times (expressed in hours) depend on the type of surgery:

| Operation Type | Stage 1 ($\tau_1$) | Stage 2 ($\tau_2$) | Stage 3 ($\tau_3$) |
| :--- | :---: | :---: | :---: |
| **Appendectomy ($A$)** | $1.0\text{ h}$ | $2.0\text{ h}$ | $0.5\text{ h}$ |
| **Tonsillectomy ($T$)** | $0.5\text{ h}$ | $2.0\text{ h}$ | $1.5\text{ h}$ |

---

## Scenario 1: Emergency Scenario

In the Emergency Scenario, patients arrive dynamically from outside according to two independent Poisson processes with arrival rates:
* $\lambda_A = 1\text{ patient/hour}$ for Appendectomy (exponential interarrival times with mean $1/\lambda_A = 1.0\text{ h}$)
* $\lambda_T = 2\text{ patients/hour}$ for Tonsillectomy (exponential interarrival times with mean $1/\lambda_T = 0.5\text{ h}$)

Patients are served on a First-In, First-Out (FIFO) basis according to their order of arrival.

### Objectives
1. **System Modeling:** Implement the three-stage queueing system with blocking in Simulink/SimEvents, parameterized by $m_1$, $m_2$, and $m_3$.
2. **Performance Evaluation:** Estimate via simulation the average flow time (total time from arrival to hospital discharge) for each patient class separately ($\overline{S}_A$ and $\overline{S}_T$) and across all patients ($\overline{S}$).
3. **Cost Optimization:** Assuming the following unitary room costs:
   * Stage-1 room: $10\text{ kEUR}$
   * Stage-2 room: $50\text{ kEUR}$
   * Stage-3 room: $2\text{ kEUR}$
   
   Determine the minimum-cost room configuration $(m_1, m_2, m_3)$ such that the overall average flow time satisfies the constraint $\overline{S} \le 20\text{ hours}$.

---

## Scenario 2: Hospital Scenario

In the Hospital Scenario, the system is analyzed over a single working day with a predetermined batch of $N = 20$ patients ($N/2 = 10$ Appendectomy and $N/2 = 10$ Tonsillectomy) already present at time $t = 0$. Since all patients have already undergone triage, their exact realizations of the service times across the three stages are known at $t = 0$.

The surgical unit operates with a single room per stage ($m_1 = 1$, $m_2 = 1$, $m_3 = 1$).

### Objectives
1. **Batch Modeling:** Implement the Simulink model for $m_1 = m_2 = m_3 = 1$ and $N = 20$, utilizing batch creation and splitting mechanisms.
2. **Scheduling Optimization:** Formulate and implement an optimization algorithm executed at $t = 0$ to determine an efficient operation sequence for the $N$ patients that minimizes the average flow time $\overline{S}$ (equivalent to minimizing the sum of completion times of the third stage).
3. **Comparative Analysis:** Compare the average flow time $\overline{S}$ achieved under the optimized patient schedule against a baseline random ordering, ensuring reproducibility by fixing the Random Number Generator (RNG) seed.

---

## Repository Structure

```text
├── emergency_driver.m       # MATLAB script for Scenario 1 initialization, simulation, and cost optimization
├── emergency_scenario.slx   # Simulink/SimEvents model for the Emergency Scenario
├── hospital_driver.m        # MATLAB script for Scenario 2 initialization and scheduling comparison
├── hospital_scenario.slx    # Simulink/SimEvents model for the Hospital Scenario
├── Optimization and Simulation for Industrial Automation - Final Project Report.pdf
├── .gitignore               # Git ignore configuration for MATLAB/Simulink temporary files and OS metadata
└── README.md                # Project documentation
```

---

## Requirements and Execution

### Prerequisites
* **MATLAB** (R2023b / R2024a or later)
* **Simulink**
* **SimEvents**
* **Optimization Toolbox**

### Running the Simulations

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/francesca-for/Optimization_and_Simulation_for_Industrial_Automation.git
   cd Optimization_and_Simulation_for_Industrial_Automation
   ```

2. Open MATLAB, set the working directory to the repository root, and execute the desired driver script:
   * **Emergency Scenario:**
     ```matlab
     run('emergency_driver.m')
     ```
   * **Hospital Scenario:**
     ```matlab
     run('hospital_driver.m')
     ```

---

## Documentation

For a detailed discussion of the model implementation, optimization algorithms, simulation setups, and numerical results, refer to the complete project report included in this repository:
* [`Optimization and Simulation for Industrial Automation - Final Project Report.pdf`](./Optimization%20and%20Simulation%20for%20Industrial%20Automation%20-%20Final%20Project%20Report.pdf)