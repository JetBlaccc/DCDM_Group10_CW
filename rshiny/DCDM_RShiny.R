# Group 10 shiny app
# tab 1: one gene, all phenotype tested
# tab 2: one phenotype, all genes tested
# tab 3: clusters of genes with similar phenotype scores
# needs db_config.R with the mysql login

library(shiny)
library(DBI)
library(ggplot2)

# connect to database
source("db_config.R")
con <- dbConnect(RMySQL::MySQL(), host = db_host, port = db_port,
                 user = db_user, password = db_password, dbname = "impc_group10")

# import data
dat <- dbGetQuery(con, "SELECT gene_symbol, parameter_id, parameter_name, procedure_name, pvalue
                        FROM v_analysis_detail
                        WHERE pvalue IS NOT NULL AND parameter_id IS NOT NULL")

groups <- dbGetQuery(con, "SELECT m.parameter_id, g.group_name
                           FROM parameter_group_map m
                           JOIN parameter_group g ON m.group_id = g.group_id")

query_genes <- dbGetQuery(con, "SELECT gene_symbol FROM query_gene")$gene_symbol

dbDisconnect(con)

# set minimum p value
min_p <- min(dat$pvalue[dat$pvalue > 0])
dat$pvalue[dat$pvalue == 0] <- min_p

# score = -log10(p), higher = more significant
dat$score <- -log10(dat$pvalue)

# procedure unknown for some parameters
dat$procedure_name[is.na(dat$procedure_name)] <- "unknown"

# dropdown lists (query genes first)
genes <- sort(unique(dat$gene_symbol))
genes <- c(query_genes, genes[!genes %in% query_genes])

# phenotypes sorted by how many genes were tested
params <- unique(dat[, c("parameter_id", "parameter_name")])
n_genes <- table(unique(dat[, c("parameter_id", "gene_symbol")])$parameter_id)
params$n <- as.numeric(n_genes[params$parameter_id])
params <- params[order(-params$n), ]
param_list <- setNames(params$parameter_id,
                       paste0(params$parameter_name, " (", params$parameter_id, ", ", params$n, " genes)"))

group_names <- sort(unique(groups$group_name))

# function to make gene x group matrix for clustering
# score = strongest -log10(p) per group, not tested = 0
get_matrix <- function(dat, min_tests, cap) {
  # keep genes with enough analyses
  n <- table(dat$gene_symbol)
  d <- dat[dat$gene_symbol %in% names(n)[n >= min_tests], ]
  # add the groups
  d <- merge(d, groups, by = "parameter_id")
  # make matrix
  m <- tapply(d$score, list(d$gene_symbol, d$group_name), max)
  m[is.na(m)] <- 0
  # cap the score
  m[m > cap] <- cap
  m
}

ui <- fluidPage(
  titlePanel("DCDM - Group 10"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("alpha", "p value threshold", value = 0.05, min = 0, max = 1, step = 0.01),
      p("plots show -log10(p), points past the dashed line are significant"),
      p(paste("genes of interest:", paste(query_genes, collapse = ", ")))
    ),
    
    mainPanel(
      tabsetPanel(
        
        tabPanel("Gene",
                 selectInput("gene", "Knockout gene", choices = genes),
                 plotOutput("genePlot", height = "600px"),
                 h4("Significant phenotypes"),
                 tableOutput("geneTable")),
        
        tabPanel("Phenotype",
                 selectInput("group", "Parameter group", choices = c("all", group_names)),
                 selectInput("param", "Phenotype", choices = param_list, width = "100%"),
                 plotOutput("paramPlot", height = "500px"),
                 h4("Significant genes"),
                 tableOutput("paramTable")),
        
        tabPanel("Clusters",
                 fluidRow(
                   column(4, numericInput("min_tests", "Min analyses per gene", value = 10, min = 1)),
                   column(4, numericInput("cap", "Cap -log10(p) at", value = 5, min = 1)),
                   column(4, sliderInput("k", "Number of clusters", min = 2, max = 10, value = 4))
                 ),
                 plotOutput("pcaPlot", height = "500px"),
                 plotOutput("heatmap", height = "600px"),
                 h4("Clusters of the genes of interest"),
                 tableOutput("clusterTable"))
      )
    )
  )
)

server <- function(input, output, session) {
  # tab 1: one gene, all phenotype tested
  gene_data <- reactive({
    d <- dat[dat$gene_symbol == input$gene, ]
    d$sig <- ifelse(d$pvalue < input$alpha, "significant", "not significant")
    d
  })
  
  output$genePlot <- renderPlot({
    d <- gene_data()
    ggplot(d, aes(x = score, y = procedure_name, colour = sig)) +
      geom_point(size = 2.5, alpha = 0.8) +
      geom_vline(xintercept = -log10(input$alpha), linetype = "dashed") +
      geom_text(data = d[d$sig == "significant", ], aes(label = parameter_name),
                size = 3, hjust = -0.1, vjust = -0.5, colour = "black") +
      scale_colour_manual(values = c("significant" = "red", "not significant" = "grey")) +
      labs(title = paste("Phenotypes tested in", input$gene, "knockout mice"),
           x = "-log10(p value)", y = "Procedure", colour = "") +
      theme_minimal()
  })
  
  output$geneTable <- renderTable({
    d <- gene_data()
    d <- d[d$pvalue < input$alpha, c("parameter_name", "procedure_name", "pvalue")]
    d[order(d$pvalue), ]
  }, digits = -3)
  
  # tab 2: one phenotype, all gene tested
  observe({
    if (input$group == "all") {
      choices <- param_list
    } else {
      ids <- groups$parameter_id[groups$group_name == input$group]
      choices <- param_list[param_list %in% ids]
    }
    updateSelectInput(session, "param", choices = choices)
  })
  
  param_data <- reactive({
    req(input$param)
    d <- dat[dat$parameter_id == input$param, ]
    # if a gene was tested twice keep the lowest p
    d <- d[order(d$pvalue), ]
    d <- d[!duplicated(d$gene_symbol), ]
    d$sig <- ifelse(d$pvalue < input$alpha, "significant", "not significant")
    d$gene_symbol <- factor(d$gene_symbol, levels = d$gene_symbol)
    d
  })
  
  output$paramPlot <- renderPlot({
    d <- param_data()
    ggplot(d, aes(x = gene_symbol, y = score, colour = sig)) +
      geom_point(size = 2.5) +
      geom_hline(yintercept = -log10(input$alpha), linetype = "dashed") +
      # label significant genes and genes of interest
      geom_text(data = d[d$sig == "significant" | d$gene_symbol %in% query_genes, ],
                aes(label = gene_symbol), size = 3, vjust = -1, colour = "black") +
      scale_colour_manual(values = c("significant" = "red", "not significant" = "grey")) +
      labs(title = paste(d$parameter_name[1], "-", nrow(d), "genes tested"),
           x = "Knockout gene (ranked)", y = "-log10(p value)", colour = "") +
      theme_minimal() +
      theme(axis.text.x = element_blank())
  })
  
  output$paramTable <- renderTable({
    d <- param_data()
    d[d$pvalue < input$alpha, c("gene_symbol", "procedure_name", "pvalue")]
  }, digits = -3)
  
  # tab 3: clusters of genes with similar phenotype scores
  cluster_data <- reactive({
    m <- get_matrix(dat, input$min_tests, input$cap)
    req(nrow(m) > input$k)
    
    # hierarchical clustering
    tree <- hclust(dist(m), method = "ward.D2")
    cl <- cutree(tree, k = input$k)
    
    # pca to show the clusters in 2d
    pca <- as.data.frame(prcomp(m)$x)
    pca$gene <- rownames(m)
    pca$cluster <- factor(cl)
    
    list(m = m, tree = tree, cl = cl, pca = pca)
  })
  
  output$pcaPlot <- renderPlot({
    pca <- cluster_data()$pca
    q <- pca[pca$gene %in% query_genes, ]
    ggplot(pca, aes(x = PC1, y = PC2, colour = cluster)) +
      geom_point(alpha = 0.6) +
      geom_point(data = q, shape = 17, size = 4) +
      geom_text(data = q, aes(label = gene), vjust = -1, colour = "black") +
      labs(title = paste(nrow(pca), "genes clustered on their parameter group scores"),
           subtitle = "triangles = genes of interest") +
      theme_minimal()
  })
  
  output$heatmap <- renderPlot({
    x <- cluster_data()
    m <- x$m
    
    # long format for ggplot, genes in the order of the tree
    d <- data.frame(gene = rep(rownames(m), ncol(m)),
                    group = rep(colnames(m), each = nrow(m)),
                    score = as.vector(m))
    d$gene <- factor(d$gene, levels = rownames(m)[x$tree$order])
    d$cluster <- factor(x$cl[as.character(d$gene)])
    
    ggplot(d, aes(x = group, y = gene, fill = score)) +
      geom_tile() +
      scale_fill_gradient(low = "white", high = "red") +
      scale_y_discrete(breaks = query_genes) +
      facet_grid(cluster ~ ., scales = "free_y", space = "free_y") +
      labs(title = "Heatmap of -log10(p) by parameter group", x = "", y = "") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$clusterTable <- renderTable({
    cl <- cluster_data()$cl
    data.frame(gene = query_genes, cluster = cl[query_genes])
  })
}

shinyApp(ui = ui, server = server)