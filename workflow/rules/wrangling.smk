rule capture_versions:
    output:
        "results/dashboard_data/versions.csv"
    shell:
        """
        echo "tool,version" > {output}
        echo "quarto,$(pixi run quarto --version 2>&1)" >> {output}
        echo "cawlign,$(pixi run cawlign --version 2>&1 | tr -d '[:space:]')" >> {output}
        SIERRA_FULL=$(pixi run sierrapy --version 2>&1)
        echo "sierrapy,$(echo "$SIERRA_FULL" | cut -d';' -f1 | sed 's/SierraPy //')" >> {output}
        echo "sierra,$(echo "$SIERRA_FULL" | cut -d';' -f2 | sed 's/^ *Sierra //')" >> {output}
        echo "hivdb,$(echo "$SIERRA_FULL" | cut -d';' -f3 | sed 's/^ *HIVdb //')" >> {output}
        echo 'hivtrace,">=0.9.2,<0.10"' >> {output}
        """

rule pipeline_attrition:
    input:
        dag = "results/dashboard_data/workflow_dag.json",
        metrics = [
            "results/metrics/validate_notifications.csv",
            "results/metrics/validate_sequences.csv",
            "results/metrics/extract_transmitted.csv",
            "results/metrics/link_sequences.csv",
        ]
    output:
        table = "results/dashboard_data/pipeline_stats.csv"
    script:
        "../scripts/pipeline_attrition.R"

rule pipeline_stats:
    output:
        "results/dashboard_data/workflow_dag.json"
    shell:
        """
        snakemake --forceall --d3dag > {output}
        """


rule wrangle_sequences:
    input:
        "results/hivtrace/prrtin.fasta_output.fasta"
    output:
        "results/dashboard_data/sequences.fasta"
    log:
        "logs/wrangle_sequences.log"
    shell:
        """
        cp {input} {output}
        """

rule wrangle_autotune:
    input:
        "results/autotune/clusters.tsv"
    output:
        autotune = "results/dashboard_data/autotune.csv"
    log:
        "logs/wrangle_autotune.log"
    shell:
        """
        csvtk tab2csv {input} > {output}
        """

rule wrangle_linelist:
    input:
        notifications_linked = "results/linked/notifications.csv",
        notifications_rejected = "results/linked/notifications_rejected.csv",
        clusters = "results/hivtrace/clustering.csv",
        subtypes = "results/dashboard_data/subtypes.csv",
        sequence_info = "results/linked/sequences.csv"
    output:
        linelist = "results/dashboard_data/linelist.csv"
    log:
        "logs/wrangle_linelist.log"
    script:
        "../scripts/wrangle_linelist.R"

rule wrangle_resistance:
    input:
        notifications = "results/linked/notifications.csv",
        mutations = expand("results/sierrapy/mutations_{gene}.csv", gene = GENES),
        drug_resistance = expand("results/sierrapy/drug_resistance_{gene}.csv", gene = GENES),
        class_resistance = expand("results/sierrapy/class_resistance_{gene}.csv", gene = GENES),
        subtypes = expand("results/sierrapy/subtypes_{gene}.csv", gene = GENES)
    output:
        mutation = "results/dashboard_data/drms.csv",
        drug = "results/dashboard_data/drug_resistance.csv",
        classes = "results/dashboard_data/class_resistance.csv",
        subtype = "results/dashboard_data/subtypes.csv"
    log:
        "logs/wrangle_resistance.log"
    script:
        "../scripts/wrangle_resistance.R"