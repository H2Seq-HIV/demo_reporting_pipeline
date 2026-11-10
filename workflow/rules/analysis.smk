rule autotune:
    input:
        aligned = "results/hivtrace/prrtin.fasta_output.fasta"
    output:
        tn93 = "results/autotune/tn93.csv",
        clusters = "results/autotune/clusters.tsv"
    params:
        threshold = config["autotune"]["threshold"]
    log:
        "logs/autotune.log"
    shell:
        """
        mkdir -p results/autotune

        pixi run -e hivtrace tn93 \
            -a skip \
            -g 0 \
            -t {params.threshold} \
            {input.aligned} \
            > {output.tn93} \
            2> {log}

        pixi run -e hivtrace hivnetworkcsv \
            -i {output.tn93} \
            -f plain \
            -A 0 \
            > {output.clusters} \
            2>> {log}
        """

rule parse_hivtrace:
    input:
        json = "results/hivtrace/hivtrace.json",
        notifications = "results/linked/notifications.csv"
    output:
        linelist = "results/hivtrace/clustering.csv",
    log:
        "logs/parse_hivtrace.log"
    script:
        "../scripts/parse_hivtrace.R"

rule hivtrace: # TODO: Eventually take scaffolds?
    input:
        sequences = "results/qc/prrtin.fasta"
    output:
        json = "results/hivtrace/hivtrace.json",
        aligned = "results/hivtrace/prrtin.fasta_output.fasta",
        tn93 = "results/hivtrace/prrtin.fasta_user.tn93output.csv"
    params:
        threshold = config["hivtrace"]["threshold"],
        ambiguities = config["hivtrace"]["ambiguities"],
        minoverlap = config["hivtrace"]["minoverlap"],
        reference = config["hivtrace"]["reference"],
        curate = config["hivtrace"]["curate"],
        filter = config["hivtrace"]["filter"]
    log:
        "logs/hivtrace.log"
    shell:
        """
        mkdir -p results/hivtrace
        ln -sfn ../qc/prrtin.fasta results/hivtrace/prrtin.fasta

        pixi run -e hivtrace hivtrace \
            --input results/hivtrace/prrtin.fasta \
            --ambiguities {params.ambiguities} \
            --fraction 0.05 \
            --skip-alignment \
            --filter {params.filter} \
            --curate {params.curate} \
            --reference {params.reference} \
            --threshold {params.threshold} \
            --minoverlap {params.minoverlap} \
            --strip_drams lewis \
            --log {log} \
            --output {output.json}
        """

rule parse_sierrapy:
    input:
        json = "results/sierrapy/{gene}.json",
        metadata = "results/linked/notifications.csv"
    output:
        drugs = "results/sierrapy/drug_resistance_{gene}.csv",
        classes = "results/sierrapy/class_resistance_{gene}.csv",
        mutations = "results/sierrapy/mutations_{gene}.csv",
        subtypes = "results/sierrapy/subtypes_{gene}.csv"
    params:
        res_cutoff = config["sierrapy"]["res_cutoff"]
    log:
        "logs/parse_sierrapy_{gene}.log"
    script:
        "../scripts/parse_sierrapy.R"

# NB all sequences used for sierrapy, but QC before HIVTrace
rule sierrapy:
    input:
        sequences = ancient("results/linked/{gene}.fasta")
    output:
        json = "results/sierrapy/{gene}.json"
    params:
        query = config['sierrapy']['query']
    log:
        "logs/sierrapy_{gene}.log"
    shell:
        """
        sierrapy fasta {input.sequences} \
            --query {params.query} \
            --no-sharding \
            --output {output.json} 2> {log}
        """
