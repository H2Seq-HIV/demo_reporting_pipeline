# Temporary pass-through until PRRT sequence QC is implemented.
rule filter_sequences: # TODO: Add scaffold and qc eventually
    input:
        sequences = "results/alignment/prrtin.fasta"
    output:
        sequences = "results/qc/prrtin.fasta"
    log:
        "logs/filter_sequences.log"
    shell:
        """
        mkdir -p results/qc
        cp {input.sequences} {output.sequences}
        """

rule alignment:
    input: "results/linked/{gene}.fasta"
    output:  "results/alignment/{gene}.fasta"
    params:
        ref = config['alignment']['reference']
    log:
        "logs/alignment_{gene}.log"
    shell:
        """
        mkdir -p results/alignment
        cawlign -r {params.ref} -f refmap -o {output} {input} 2> {log}
        """

rule convert_fasta:
    input:
        "results/linked/sequences.csv"
    output:
        "results/linked/{gene}.fasta"
    params:
        column = lambda wildcards: f"sequence_{wildcards.gene}"
    log:
        "logs/convert_fasta_{gene}.log"
    shell:
        """
        csvtk cut -f id,{params.column} {input} | \
        csvtk filter2 -f '${params.column} != "NA"' | \
        csvtk csv2tab | \
        csvtk del-header | \
        seqkit tab2fx \
        > {output} \
        2>> {log}
        """
