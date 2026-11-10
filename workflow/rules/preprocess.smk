# Add rules on filtering notifications and sequences

rule link_sequences:
    input:
        notifications = "results/data_validated/notifications.csv",
        sequences = "results/extract_transmitted/sequences.csv"
    output:
        notifications = "results/linked/notifications.csv",
        sequences = "results/linked/sequences.csv",
        sequences_rejected = "results/linked/sequences_rejected.csv",
        notifications_rejected = "results/linked/notifications_rejected.csv",
        metrics = "results/metrics/link_sequences.csv"
    params:
        max_lag_days = config["linkage_filters"]["max_lag_days"]
    log:
        "logs/link_sequences.log"
    script:
        "../scripts/linkage.R"

rule extract_transmitted:
    input:
        sequences = "results/data_validated/sequences.csv"
    output:
        sequences = "results/extract_transmitted/sequences.csv",
        metrics = "results/metrics/extract_transmitted.csv"
    log: 
        "logs/extract_transmitted.log"
    script:
        "../scripts/extract_transmitted.R"


rule validate_notifications:
    input:
        notifications = config["notification_data"]
    output:
        notifications = "results/data_validated/notifications.csv",
        rejected = "results/data_validated/notifications_rejected.csv",
        metrics = "results/metrics/validate_notifications.csv"
    log:
        report = "logs/pointblank_notifications_report.html"
    script:
        "../scripts/validate_notifications.R"

rule validate_sequences:
    input:
        sequences = config["sequence_data"]
    output:
        sequences = "results/data_validated/sequences.csv",
        rejected = "results/data_validated/sequences_rejected.csv",
        metrics = "results/metrics/validate_sequences.csv"
    log:
        report = "logs/pointblank_sequences_report.html"
    script:
        "../scripts/validate_sequences.R"