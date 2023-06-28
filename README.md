
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
#> Warning: package 'Rvcg' was built under R version 4.2.2
library(rgl)
library(rphylopic)
#> Warning: package 'rphylopic' was built under R version 4.2.3
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::get_uuid(n = 10000)
#> Warning in rphylopic::get_uuid(n = 10000): Only 7777 items are available.
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::get_phylopic(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::get_attribution(x)$contributor})
```

## Artists whose work is showcased:

Guillaume Dera, T. Michael Keesey, Taro Maeda, Tasman Dixon, Russell
Engelman, Gareth Monger, Gemma Martínez-Redondo, Ray Chatterji, Michelle
Site, Nathan Hermann, Lauren Anderson, Michael Scroggie, Andy Wilson,
Katy Lawler, Margot Michaud, subhumanfreaks, Vijay Karthick, Stuart
Humphries, Ignacio Contreras, Ferran Sayol, Yan Wong, Denis Lafage, Matt
Hayes, Livio Ruzzante, Jonathan Wells, Pete Buchholz, Jose Carlos
Arenas-Monroy, Christine Axon, Sarah Werning, Daniel Stadtmauer, Zimices
(Julián Bayona), Emily Troyer, Steven Traver, Alex Slavenko, James
Bernot, JFstudios, Arthur S. Brum, Carlos Cano-Barbacil, Matthew Crook,
Chloé Schmidt, Scott Hartman, Kai Caspar, Markus Grohme, Mason McNair,
César Camilo Julián Caballero, Martin R Smith, Katie Collins, Jagged
Fang Designs, Christoph Schomburg, Jake Warner, monatkat, Trond Oskars,
Emilien Decaux, Fernando Carezzano, B. Duygu Özpolat, Xavier Jenkins,
Antoine Verrière, Caleb Brown, Andrew Farke, Michele M Tobias, Timothy
Bartley, Chris Masna, Gabriela Palomo-Munoz, Alexander Schmidt-Lebuhn,
Wani2Y, seung9park, Mathew Wedel, Tessa Rehill, thefunkmonk, Patricia
Pilatti, Konsta Happonen, Gopal Murali, Sergio A. Muñoz-Gómez, Levi
Simons, Ben Moon, Darrin Schultz, Roberto Diaz Sibaja, Kai Sonder,
Joanna Wolfe, Malio Kodis, Iain Reid, Chris Hamilton, Darren J. Parker,
xgirouxb, Matthew Dempsey, Tracy Heath, Armin Reindl, Jaime Headden,
yoshi50, Agnello Picorelli, Melissa Broussard, Matt Martyniuk, rafael
maia, plag665, Miguel M. Sandin, Christina Zdenek, Rebecca Groom, Maxime
Dahirel, Ivan Iofrida, Robert Gay, Ludwik Gąsiorowski, Rene Martin,
Bruno Maggia, Beth Reinke, Michael Day, Alexandre Vong, Julio Francisco
Garza Lorenzo, maija.karala, Noah Schlottman, Sean McCann, risiattoart,
Darius Nau, Sofía Terán Sánchez, Jamie Whitehouse, Maggie J Watson, Jon
Hill, Kamil S. Jaron, David García-Callejas, Becky Barnes, Felix Vaux,
Joel Vikberg Wernström, Lucas Carbone, Rachael Joakim, Erika Schumacher,
Diana Pomeroy, Mike Taylor, Ricarda Pätsch, Emily Willoughby
e.deinonychus, Martin Bulla, Collin Gross, tmccraney, Tyler Greenfield,
Ingo Braasch, François Michonneau, Nicolas Bekkouche, severine Martini,
Timothée Poisot, ZT Kulik, Geoff Shaw

## Detailed credit:

|     | Image X Coord | Image Y Coord | Contributor                    |
|----:|--------------:|--------------:|:-------------------------------|
|   1 |    916.954410 |    635.778506 | Guillaume Dera                 |
|   2 |    348.602598 |    164.128518 | T. Michael Keesey              |
|   3 |    447.672998 |    641.913644 | Taro Maeda                     |
|   4 |    558.765694 |    519.125073 | Tasman Dixon                   |
|   5 |    210.440669 |    410.048248 | T. Michael Keesey              |
|   6 |    155.988970 |    346.374621 | T. Michael Keesey              |
|   7 |    651.133196 |     82.389717 | Russell Engelman               |
|   8 |    882.615042 |    444.375850 | Gareth Monger                  |
|   9 |    702.283557 |    252.846212 | Gemma Martínez-Redondo         |
|  10 |    172.634640 |    155.640371 | Ray Chatterji                  |
|  11 |    519.375129 |    360.722481 | T. Michael Keesey              |
|  12 |    864.531231 |    271.762717 | Michelle Site                  |
|  13 |    340.234585 |    326.148319 | Nathan Hermann                 |
|  14 |    629.990886 |    709.769788 | Guillaume Dera                 |
|  15 |    809.591527 |    136.453639 | Lauren Anderson                |
|  16 |    533.963317 |    127.828331 | T. Michael Keesey              |
|  17 |    120.012283 |    664.325762 | Guillaume Dera                 |
|  18 |    330.901998 |    434.183877 | Michael Scroggie               |
|  19 |    269.868416 |    626.611979 | T. Michael Keesey              |
|  20 |    223.731250 |    250.166259 | Andy Wilson                    |
|  21 |    443.614233 |    476.793399 | Andy Wilson                    |
|  22 |    254.657714 |    134.929740 | Katy Lawler                    |
|  23 |    765.597678 |    597.168155 | Margot Michaud                 |
|  24 |    688.947269 |     43.427852 | subhumanfreaks                 |
|  25 |    658.252860 |    528.063789 | T. Michael Keesey              |
|  26 |     34.744062 |    176.844820 | T. Michael Keesey              |
|  27 |    152.502082 |     56.847879 | Vijay Karthick                 |
|  28 |    164.133170 |    522.610250 | Stuart Humphries               |
|  29 |    956.987850 |     65.341619 | Ignacio Contreras              |
|  30 |    446.341453 |     94.376458 | Guillaume Dera                 |
|  31 |    923.071651 |    729.999712 | Guillaume Dera                 |
|  32 |    822.210825 |     50.758817 | Ferran Sayol                   |
|  33 |    386.432813 |    762.508584 | Yan Wong                       |
|  34 |    157.238998 |    451.024237 | Denis Lafage                   |
|  35 |    951.034144 |    519.116939 | Matt Hayes                     |
|  36 |    239.582822 |    753.849223 | T. Michael Keesey              |
|  37 |    768.051540 |    782.090832 | Ferran Sayol                   |
|  38 |    831.994365 |    520.549334 | Livio Ruzzante                 |
|  39 |    805.567323 |    713.229312 | T. Michael Keesey              |
|  40 |    387.210421 |    385.512526 | Jonathan Wells                 |
|  41 |    700.434178 |    405.334528 | T. Michael Keesey              |
|  42 |    919.327764 |    366.764899 | Pete Buchholz                  |
|  43 |    127.255073 |    238.325534 | Michael Scroggie               |
|  44 |    911.689927 |    218.355207 | Jose Carlos Arenas-Monroy      |
|  45 |    290.225666 |    515.099305 | Christine Axon                 |
|  46 |     63.970293 |    752.089457 | T. Michael Keesey              |
|  47 |    717.773295 |    674.145789 | Sarah Werning                  |
|  48 |    505.387843 |    739.339351 | Daniel Stadtmauer              |
|  49 |    316.904771 |     70.038070 | Zimices (Julián Bayona)        |
|  50 |    357.280016 |    254.375097 | Nathan Hermann                 |
|  51 |     68.824791 |    292.734692 | Margot Michaud                 |
|  52 |    726.413114 |    350.126510 | Emily Troyer                   |
|  53 |    249.232582 |    554.476819 | Gareth Monger                  |
|  54 |    246.796317 |    711.186341 | T. Michael Keesey              |
|  55 |     91.230072 |    396.387859 | T. Michael Keesey              |
|  56 |    978.171664 |    277.495245 | Ferran Sayol                   |
|  57 |     48.704322 |    507.641697 | Guillaume Dera                 |
|  58 |    609.550172 |    114.638053 | T. Michael Keesey              |
|  59 |    381.043946 |    294.421314 | Steven Traver                  |
|  60 |    896.747970 |    165.338337 | Alex Slavenko                  |
|  61 |    956.579909 |    130.064565 | James Bernot                   |
|  62 |    734.994442 |    131.647520 | JFstudios                      |
|  63 |    485.361476 |    223.750902 | Arthur S. Brum                 |
|  64 |   1002.165262 |    686.675205 | Gareth Monger                  |
|  65 |    821.491998 |    366.669299 | Gareth Monger                  |
|  66 |    730.805307 |    494.776042 | Guillaume Dera                 |
|  67 |    426.103260 |     25.822628 | Margot Michaud                 |
|  68 |    168.339023 |    777.992693 | Carlos Cano-Barbacil           |
|  69 |    364.579158 |    529.201373 | Guillaume Dera                 |
|  70 |    485.794386 |    529.715706 | Gareth Monger                  |
|  71 |    799.452378 |     49.225477 | Matthew Crook                  |
|  72 |    951.167882 |    404.081267 | Chloé Schmidt                  |
|  73 |    799.810144 |    548.930171 | T. Michael Keesey              |
|  74 |    624.056913 |    371.768773 | T. Michael Keesey              |
|  75 |    838.722480 |    485.350783 | Scott Hartman                  |
|  76 |    164.327579 |    280.738789 | T. Michael Keesey              |
|  77 |    560.788090 |    641.314499 | Kai Caspar                     |
|  78 |     74.016985 |      6.905825 | Markus Grohme                  |
|  79 |    617.637054 |    297.492034 | Zimices (Julián Bayona)        |
|  80 |     70.708827 |    115.117075 | Mason McNair                   |
|  81 |    416.726894 |    142.165336 | César Camilo Julián Caballero  |
|  82 |    105.931931 |    490.924154 | Scott Hartman                  |
|  83 |   1011.349072 |    189.667411 | Guillaume Dera                 |
|  84 |    811.860823 |    218.279217 | T. Michael Keesey              |
|  85 |    604.058966 |    134.901019 | T. Michael Keesey              |
|  86 |     16.433996 |    374.104977 | Martin R Smith                 |
|  87 |    817.885378 |     14.125215 | Tasman Dixon                   |
|  88 |    274.747133 |     19.627748 | Katie Collins                  |
|  89 |    575.991844 |     22.329711 | Andy Wilson                    |
|  90 |    423.819636 |    547.799659 | Jagged Fang Designs            |
|  91 |    793.271456 |    529.062954 | Christoph Schomburg            |
|  92 |     76.479040 |    423.106078 | T. Michael Keesey              |
|  93 |    564.209822 |    466.987517 | Jose Carlos Arenas-Monroy      |
|  94 |    743.690743 |    492.816571 | Jake Warner                    |
|  95 |    668.032289 |    144.835385 | monatkat                       |
|  96 |    212.869174 |    620.279998 | Guillaume Dera                 |
|  97 |    324.057170 |    697.479940 | T. Michael Keesey              |
|  98 |     49.299137 |    339.337849 | Guillaume Dera                 |
|  99 |    283.956333 |    488.673928 | Nathan Hermann                 |
| 100 |    485.269164 |     99.065231 | Andy Wilson                    |
| 101 |     38.325988 |    636.114902 | Trond Oskars                   |
| 102 |    801.760094 |    351.706752 | Zimices (Julián Bayona)        |
| 103 |    101.015748 |    144.946391 | Emilien Decaux                 |
| 104 |    403.746375 |    213.160930 | Fernando Carezzano             |
| 105 |    288.419631 |    281.186733 | B. Duygu Özpolat               |
| 106 |    665.054405 |    606.480360 | T. Michael Keesey              |
| 107 |    805.341192 |    462.759850 | Xavier Jenkins                 |
| 108 |     64.175966 |     31.174378 | Guillaume Dera                 |
| 109 |    275.872413 |    388.108972 | Andy Wilson                    |
| 110 |    652.276604 |     16.122022 | Mason McNair                   |
| 111 |    311.738237 |    624.627235 | Antoine Verrière               |
| 112 |    861.186416 |    100.254093 | Guillaume Dera                 |
| 113 |    680.496057 |    630.292036 | Ignacio Contreras              |
| 114 |    196.021797 |    379.441122 | Jagged Fang Designs            |
| 115 |    616.840127 |    127.015916 | Caleb Brown                    |
| 116 |     78.685341 |    166.621698 | Matthew Crook                  |
| 117 |    400.936549 |    703.068047 | Andy Wilson                    |
| 118 |    625.566493 |    162.539690 | Andrew Farke                   |
| 119 |     31.551076 |    329.913443 | T. Michael Keesey              |
| 120 |    564.773341 |    576.808122 | Guillaume Dera                 |
| 121 |    761.086202 |     42.600294 | T. Michael Keesey              |
| 122 |    384.263772 |    538.319920 | Guillaume Dera                 |
| 123 |    102.845822 |    789.456507 | Michele M Tobias               |
| 124 |    121.059053 |    174.463236 | T. Michael Keesey              |
| 125 |     60.925728 |     84.705083 | Jose Carlos Arenas-Monroy      |
| 126 |     36.321405 |    670.465289 | Timothy Bartley                |
| 127 |     93.386666 |    314.810024 | Scott Hartman                  |
| 128 |    818.382697 |    234.730800 | T. Michael Keesey              |
| 129 |    549.216341 |    100.327652 | Chris Masna                    |
| 130 |    854.027189 |    151.788271 | Andy Wilson                    |
| 131 |     79.012512 |    521.429377 | Margot Michaud                 |
| 132 |    566.289743 |    706.042081 | Trond Oskars                   |
| 133 |     59.512312 |     68.220722 | Guillaume Dera                 |
| 134 |    580.277530 |    221.632167 | Guillaume Dera                 |
| 135 |    103.779747 |    230.085968 | Guillaume Dera                 |
| 136 |    529.905376 |    568.185421 | Matthew Crook                  |
| 137 |    591.601220 |    402.524183 | Andy Wilson                    |
| 138 |   1008.540863 |    439.146108 | T. Michael Keesey              |
| 139 |    211.181294 |     99.630314 | Gabriela Palomo-Munoz          |
| 140 |    673.649620 |    718.665959 | Ferran Sayol                   |
| 141 |    615.208168 |    441.281269 | T. Michael Keesey              |
| 142 |    885.869053 |    566.426734 | Steven Traver                  |
| 143 |    281.683783 |    158.777386 | Gabriela Palomo-Munoz          |
| 144 |    722.276187 |    757.015964 | Alexander Schmidt-Lebuhn       |
| 145 |   1007.605522 |    464.848962 | Christoph Schomburg            |
| 146 |    941.491692 |    346.758821 | Wani2Y                         |
| 147 |    736.024053 |     88.717070 | Nathan Hermann                 |
| 148 |    981.128401 |    102.074812 | Margot Michaud                 |
| 149 |    280.113817 |    225.542006 | Matthew Crook                  |
| 150 |    974.460810 |    776.959140 | Andy Wilson                    |
| 151 |    989.117796 |    605.500252 | Ferran Sayol                   |
| 152 |    587.512035 |    600.414883 | JFstudios                      |
| 153 |    486.948026 |    780.395387 | seung9park                     |
| 154 |    475.592572 |    270.717162 | Mathew Wedel                   |
| 155 |    919.048956 |    328.172471 | Guillaume Dera                 |
| 156 |     19.861757 |    526.210897 | Markus Grohme                  |
| 157 |   1003.524883 |    344.155671 | Margot Michaud                 |
| 158 |    848.582891 |    310.375745 | Zimices (Julián Bayona)        |
| 159 |    773.458784 |    460.283944 | Andy Wilson                    |
| 160 |    596.897380 |     40.243949 | Tessa Rehill                   |
| 161 |    192.805061 |    280.073624 | Guillaume Dera                 |
| 162 |    246.242626 |    452.308519 | Mason McNair                   |
| 163 |     15.604685 |    592.810898 | T. Michael Keesey              |
| 164 |    261.878510 |    732.547859 | thefunkmonk                    |
| 165 |    526.679630 |    195.314401 | T. Michael Keesey              |
| 166 |    479.469384 |    191.989170 | Patricia Pilatti               |
| 167 |   1001.833428 |    380.554649 | Ignacio Contreras              |
| 168 |    903.152020 |    403.158458 | Konsta Happonen                |
| 169 |    174.668922 |    572.786764 | Nathan Hermann                 |
| 170 |    721.628163 |    161.904293 | Nathan Hermann                 |
| 171 |     28.352842 |     35.351888 | Gopal Murali                   |
| 172 |    232.165772 |    672.120957 | Jagged Fang Designs            |
| 173 |   1001.690439 |    418.555106 | T. Michael Keesey              |
| 174 |    774.397486 |     16.370318 | Steven Traver                  |
| 175 |    209.015879 |    480.618250 | T. Michael Keesey              |
| 176 |    897.922178 |     84.066624 | Sergio A. Muñoz-Gómez          |
| 177 |    697.623490 |    756.989107 | Margot Michaud                 |
| 178 |    101.460870 |    550.726299 | T. Michael Keesey              |
| 179 |     94.012593 |    440.961103 | Ferran Sayol                   |
| 180 |    597.691352 |    565.892061 | Matthew Crook                  |
| 181 |     16.146928 |    774.428530 | Scott Hartman                  |
| 182 |     33.816506 |    560.345327 | Levi Simons                    |
| 183 |    619.885857 |    324.392173 | Ben Moon                       |
| 184 |    102.620293 |    268.795109 | Pete Buchholz                  |
| 185 |    857.115491 |    648.398739 | Ferran Sayol                   |
| 186 |     14.273164 |    103.890474 | Steven Traver                  |
| 187 |    392.646359 |      8.357819 | Margot Michaud                 |
| 188 |    976.596424 |    164.150967 | Darrin Schultz                 |
| 189 |    426.071403 |    782.947373 | Tasman Dixon                   |
| 190 |    177.527387 |    213.008766 | Roberto Diaz Sibaja            |
| 191 |    585.160321 |     65.745685 | Gareth Monger                  |
| 192 |    397.661960 |    719.513864 | Zimices (Julián Bayona)        |
| 193 |    266.721038 |    201.378341 | César Camilo Julián Caballero  |
| 194 |    336.166191 |     24.240041 | Andy Wilson                    |
| 195 |   1006.664194 |    767.062688 | Kai Caspar                     |
| 196 |    314.898079 |    596.083868 | Scott Hartman                  |
| 197 |   1008.904410 |    581.539183 | Scott Hartman                  |
| 198 |    917.253766 |      9.768536 | Mathew Wedel                   |
| 199 |    634.781798 |    632.569880 | T. Michael Keesey              |
| 200 |    773.486690 |    641.446645 | Jagged Fang Designs            |
| 201 |    605.423615 |    775.607115 | Jagged Fang Designs            |
| 202 |    263.119159 |    332.892287 | Guillaume Dera                 |
| 203 |    232.846212 |     25.587030 | Guillaume Dera                 |
| 204 |    888.762988 |     52.878932 | Andy Wilson                    |
| 205 |     16.888756 |    470.940098 | Jose Carlos Arenas-Monroy      |
| 206 |    620.899154 |     31.670474 | Kai Sonder                     |
| 207 |    919.986949 |    469.164769 | Andy Wilson                    |
| 208 |    729.206337 |    195.544347 | Katie Collins                  |
| 209 |    829.053392 |    107.151627 | Joanna Wolfe                   |
| 210 |     71.827226 |    555.371653 | Malio Kodis                    |
| 211 |    850.236246 |    241.285179 | Guillaume Dera                 |
| 212 |     41.875700 |    589.315607 | Ferran Sayol                   |
| 213 |    555.371734 |    776.983881 | Zimices (Julián Bayona)        |
| 214 |    645.637110 |    417.648013 | Guillaume Dera                 |
| 215 |    320.339229 |    479.498888 | Scott Hartman                  |
| 216 |    653.789434 |    785.760524 | Timothy Bartley                |
| 217 |    289.119363 |    109.771449 | T. Michael Keesey              |
| 218 |     89.042074 |    468.832132 | Guillaume Dera                 |
| 219 |    562.513740 |     53.374671 | Jagged Fang Designs            |
| 220 |    764.417499 |    303.749157 | Tasman Dixon                   |
| 221 |    374.427324 |    194.019189 | Andy Wilson                    |
| 222 |    771.272821 |    108.514931 | Iain Reid                      |
| 223 |    890.038821 |    317.106469 | T. Michael Keesey              |
| 224 |    690.752555 |    589.498258 | Guillaume Dera                 |
| 225 |    405.994677 |    503.093826 | Andrew Farke                   |
| 226 |    242.911354 |    378.069134 | Chris Hamilton                 |
| 227 |    443.555542 |    188.576204 | Guillaume Dera                 |
| 228 |    590.069307 |    276.373637 | Zimices (Julián Bayona)        |
| 229 |    553.558329 |     84.467170 | T. Michael Keesey              |
| 230 |    571.595188 |    437.544267 | Ferran Sayol                   |
| 231 |    376.989734 |     45.010106 | Guillaume Dera                 |
| 232 |     26.067560 |    517.135479 | Gareth Monger                  |
| 233 |    374.300795 |    473.667136 | Martin R Smith                 |
| 234 |    371.132456 |    725.756950 | Darren J. Parker               |
| 235 |    883.031778 |    137.610222 | Scott Hartman                  |
| 236 |    976.295087 |    639.795803 | Ferran Sayol                   |
| 237 |    595.925751 |    644.810450 | xgirouxb                       |
| 238 |    435.327531 |    273.384511 | Guillaume Dera                 |
| 239 |    992.400030 |    571.745524 | Guillaume Dera                 |
| 240 |    577.231755 |    792.333039 | Markus Grohme                  |
| 241 |    862.001072 |    627.937537 | Jagged Fang Designs            |
| 242 |    655.897960 |    206.114421 | T. Michael Keesey              |
| 243 |     15.147880 |    153.741889 | Margot Michaud                 |
| 244 |     21.156322 |    135.867427 | seung9park                     |
| 245 |    285.461909 |    357.967397 | Roberto Diaz Sibaja            |
| 246 |    429.410300 |    523.191066 | Vijay Karthick                 |
| 247 |    903.162368 |    236.027011 | Matthew Dempsey                |
| 248 |     16.166025 |    615.811794 | Guillaume Dera                 |
| 249 |     29.913125 |     15.700615 | Tracy Heath                    |
| 250 |   1000.099738 |    221.097682 | Armin Reindl                   |
| 251 |    170.235847 |    487.430578 | Ignacio Contreras              |
| 252 |    785.951098 |    192.006734 | T. Michael Keesey              |
| 253 |    612.776884 |    227.201338 | Jaime Headden                  |
| 254 |    406.682129 |    437.924754 | Zimices (Julián Bayona)        |
| 255 |    228.165036 |     59.807458 | T. Michael Keesey              |
| 256 |    233.226354 |    320.004207 | T. Michael Keesey              |
| 257 |    419.294482 |    341.541693 | yoshi50                        |
| 258 |    770.023730 |    145.443966 | Scott Hartman                  |
| 259 |    686.474865 |    691.218319 | Gareth Monger                  |
| 260 |    453.363196 |    436.286484 | Matthew Crook                  |
| 261 |    410.537442 |    174.294275 | Guillaume Dera                 |
| 262 |    739.724548 |     23.121339 | Agnello Picorelli              |
| 263 |    804.306671 |     86.859422 | Melissa Broussard              |
| 264 |    972.353873 |    572.706775 | Matt Martyniuk                 |
| 265 |    788.713119 |    281.536679 | T. Michael Keesey              |
| 266 |     60.550565 |    151.955815 | Martin R Smith                 |
| 267 |    556.214273 |    248.826044 | Margot Michaud                 |
| 268 |    704.267696 |    100.080016 | Armin Reindl                   |
| 269 |     35.333069 |    705.701698 | rafael maia                    |
| 270 |    517.527422 |    484.424704 | plag665                        |
| 271 |    878.859487 |    191.813825 | Margot Michaud                 |
| 272 |    229.927151 |    576.848324 | T. Michael Keesey              |
| 273 |    455.718586 |    730.298385 | Levi Simons                    |
| 274 |    441.830641 |    434.128794 | Gareth Monger                  |
| 275 |    917.487688 |    183.138358 | Margot Michaud                 |
| 276 |    585.787306 |    609.210044 | T. Michael Keesey              |
| 277 |    766.677010 |    624.786028 | T. Michael Keesey              |
| 278 |    448.733266 |    164.939753 | T. Michael Keesey              |
| 279 |    469.122767 |    454.982990 | Gareth Monger                  |
| 280 |    830.734124 |    773.259733 | Mason McNair                   |
| 281 |    523.234643 |    788.400897 | T. Michael Keesey              |
| 282 |   1019.091764 |    634.884370 | Guillaume Dera                 |
| 283 |    855.246626 |    568.901994 | T. Michael Keesey              |
| 284 |    959.595627 |    563.244063 | Scott Hartman                  |
| 285 |    308.117026 |    232.158873 | Ferran Sayol                   |
| 286 |     64.688555 |    209.658031 | Guillaume Dera                 |
| 287 |    971.124767 |     23.881994 | Iain Reid                      |
| 288 |    824.053245 |    507.495760 | Miguel M. Sandin               |
| 289 |    111.494664 |    479.720900 | Christina Zdenek               |
| 290 |    236.454935 |    431.679525 | Jake Warner                    |
| 291 |    865.593619 |    390.825074 | Gareth Monger                  |
| 292 |    864.196301 |    768.085227 | Rebecca Groom                  |
| 293 |    320.481970 |    579.706666 | Jose Carlos Arenas-Monroy      |
| 294 |    935.539007 |    189.014132 | Ferran Sayol                   |
| 295 |    324.615027 |    732.702873 | T. Michael Keesey              |
| 296 |    495.010606 |     17.582091 | Matthew Crook                  |
| 297 |    813.402576 |    648.240172 | Maxime Dahirel                 |
| 298 |    867.350409 |    719.493905 | T. Michael Keesey              |
| 299 |    748.274976 |    680.794604 | Matthew Crook                  |
| 300 |    687.335860 |    204.223897 | Gareth Monger                  |
| 301 |    490.449660 |    470.847548 | Ivan Iofrida                   |
| 302 |    347.366082 |    356.067242 | Melissa Broussard              |
| 303 |    873.139730 |    781.370716 | Matthew Crook                  |
| 304 |    300.282039 |    651.705647 | Livio Ruzzante                 |
| 305 |    998.963347 |     14.776725 | Robert Gay                     |
| 306 |    597.195717 |    669.188630 | Scott Hartman                  |
| 307 |    240.845305 |    478.763418 | T. Michael Keesey              |
| 308 |    999.524852 |     83.495414 | Steven Traver                  |
| 309 |    388.426526 |     71.055303 | Ignacio Contreras              |
| 310 |    745.795245 |    524.988956 | Margot Michaud                 |
| 311 |    314.604295 |    783.914849 | T. Michael Keesey              |
| 312 |    862.123553 |    743.659714 | Ludwik Gąsiorowski             |
| 313 |    705.771250 |    485.385346 | Guillaume Dera                 |
| 314 |    846.561956 |    555.659463 | Margot Michaud                 |
| 315 |    814.364107 |    302.690800 | Rene Martin                    |
| 316 |    435.140140 |    247.593417 | Margot Michaud                 |
| 317 |    930.379437 |    266.720522 | Matthew Crook                  |
| 318 |    667.212567 |    756.895960 | Steven Traver                  |
| 319 |    921.220359 |    791.744304 | Markus Grohme                  |
| 320 |     19.820215 |     72.250676 | Gareth Monger                  |
| 321 |    748.479246 |     71.829306 | Bruno Maggia                   |
| 322 |    891.944149 |    482.291682 | Jagged Fang Designs            |
| 323 |    216.444881 |    788.312856 | Jaime Headden                  |
| 324 |    332.302428 |    617.240713 | Beth Reinke                    |
| 325 |    341.314966 |    312.623431 | Michael Day                    |
| 326 |    922.825935 |    304.267505 | Carlos Cano-Barbacil           |
| 327 |    621.611362 |    780.081691 | Scott Hartman                  |
| 328 |    206.846270 |    500.056333 | Livio Ruzzante                 |
| 329 |    921.849771 |    576.162019 | Guillaume Dera                 |
| 330 |     16.250323 |    661.235803 | Mason McNair                   |
| 331 |    962.445339 |    193.737471 | Michael Scroggie               |
| 332 |    682.871657 |    560.425320 | Christina Zdenek               |
| 333 |     13.195491 |    424.128042 | T. Michael Keesey              |
| 334 |    146.138415 |    319.132778 | T. Michael Keesey              |
| 335 |     82.908524 |     28.650091 | Alexandre Vong                 |
| 336 |    828.188623 |    324.244640 | Tasman Dixon                   |
| 337 |    136.989916 |      5.416260 | T. Michael Keesey              |
| 338 |    691.070080 |    315.468307 | Yan Wong                       |
| 339 |    781.639009 |    164.952377 | T. Michael Keesey              |
| 340 |    284.016587 |    187.573822 | Guillaume Dera                 |
| 341 |    561.085849 |     37.702555 | Julio Francisco Garza Lorenzo  |
| 342 |   1002.430975 |     48.365799 | Russell Engelman               |
| 343 |    214.490858 |     80.505511 | Andy Wilson                    |
| 344 |    250.394115 |     50.324699 | Guillaume Dera                 |
| 345 |    628.458723 |    465.508586 | Matthew Crook                  |
| 346 |    577.061861 |    746.600027 | T. Michael Keesey              |
| 347 |    324.992466 |    647.327030 | maija.karala                   |
| 348 |    802.783215 |    428.175330 | Maxime Dahirel                 |
| 349 |    854.126033 |    197.307651 | T. Michael Keesey              |
| 350 |    689.881935 |    166.166254 | Andy Wilson                    |
| 351 |    607.974343 |    622.093775 | T. Michael Keesey              |
| 352 |    698.339907 |    493.131716 | Guillaume Dera                 |
| 353 |    590.457183 |    686.962149 | Matthew Crook                  |
| 354 |    695.329158 |    189.987762 | Noah Schlottman                |
| 355 |    314.666614 |    373.773158 | Guillaume Dera                 |
| 356 |    448.734699 |    401.183903 | Andy Wilson                    |
| 357 |    269.777641 |    464.810318 | T. Michael Keesey              |
| 358 |    866.530992 |    669.571202 | Sean McCann                    |
| 359 |    786.546677 |    242.855230 | T. Michael Keesey              |
| 360 |   1013.568191 |    123.876343 | Guillaume Dera                 |
| 361 |    198.496760 |    583.320705 | T. Michael Keesey              |
| 362 |    533.695394 |    250.753817 | Guillaume Dera                 |
| 363 |    624.861239 |    152.182169 | T. Michael Keesey              |
| 364 |    745.608887 |    744.464808 | T. Michael Keesey              |
| 365 |    498.591250 |    214.057442 | Roberto Diaz Sibaja            |
| 366 |    458.756449 |    553.544160 | Guillaume Dera                 |
| 367 |     16.364629 |     45.965000 | risiattoart                    |
| 368 |    308.605904 |    759.271614 | T. Michael Keesey              |
| 369 |    545.671253 |    605.326203 | T. Michael Keesey              |
| 370 |     44.950270 |    688.630840 | Gareth Monger                  |
| 371 |    975.082105 |    754.664589 | T. Michael Keesey              |
| 372 |    735.189247 |    565.535531 | Scott Hartman                  |
| 373 |    381.762573 |    488.437355 | T. Michael Keesey              |
| 374 |    993.929378 |     29.828803 | Andy Wilson                    |
| 375 |     64.736669 |    105.137619 | T. Michael Keesey              |
| 376 |    775.961851 |    649.312867 | Andy Wilson                    |
| 377 |    581.739064 |    104.964949 | Darius Nau                     |
| 378 |    278.768530 |    250.458011 | Margot Michaud                 |
| 379 |    209.860059 |    307.691730 | Zimices (Julián Bayona)        |
| 380 |    997.867448 |    360.421245 | Margot Michaud                 |
| 381 |    261.921617 |    790.441643 | Andy Wilson                    |
| 382 |    770.222488 |    417.307996 | Jaime Headden                  |
| 383 |    612.761169 |    180.440620 | Andy Wilson                    |
| 384 |    296.666115 |    137.476586 | Jose Carlos Arenas-Monroy      |
| 385 |    108.999035 |    505.902523 | Margot Michaud                 |
| 386 |    887.570264 |    121.744091 | Sofía Terán Sánchez            |
| 387 |    258.985338 |    565.768751 | Andy Wilson                    |
| 388 |   1004.248623 |    542.227859 | Guillaume Dera                 |
| 389 |    764.419943 |    546.416738 | Jamie Whitehouse               |
| 390 |    536.705241 |    689.201203 | Maggie J Watson                |
| 391 |    600.880415 |    370.812444 | Andy Wilson                    |
| 392 |     62.178950 |    368.370979 | Jon Hill                       |
| 393 |    609.378319 |    424.042271 | Kamil S. Jaron                 |
| 394 |    748.837179 |    222.202928 | Guillaume Dera                 |
| 395 |     36.293437 |    437.037899 | Tasman Dixon                   |
| 396 |    939.305528 |    281.550378 | T. Michael Keesey              |
| 397 |    745.019808 |    467.483497 | Zimices (Julián Bayona)        |
| 398 |    942.851329 |    312.380184 | T. Michael Keesey              |
| 399 |    909.138881 |     23.979821 | Julio Francisco Garza Lorenzo  |
| 400 |   1017.312202 |    732.748387 | David García-Callejas          |
| 401 |    125.945955 |    427.192594 | Becky Barnes                   |
| 402 |     16.751568 |    537.263548 | Margot Michaud                 |
| 403 |    213.588092 |    390.137736 | Noah Schlottman                |
| 404 |    396.922431 |     97.317459 | T. Michael Keesey              |
| 405 |    173.232094 |    391.429302 | Felix Vaux                     |
| 406 |    342.119421 |    219.320897 | T. Michael Keesey              |
| 407 |    301.457134 |    380.689311 | Tasman Dixon                   |
| 408 |    512.978240 |    245.561978 | Matthew Crook                  |
| 409 |    968.850499 |    203.368997 | Jagged Fang Designs            |
| 410 |    937.737357 |    470.480613 | Matthew Crook                  |
| 411 |    792.120722 |    475.530311 | Rebecca Groom                  |
| 412 |     16.962149 |    262.945752 | Mason McNair                   |
| 413 |    219.513057 |    655.066136 | Margot Michaud                 |
| 414 |     80.178072 |    205.992797 | Joel Vikberg Wernström         |
| 415 |    507.647081 |    507.523976 | Matthew Crook                  |
| 416 |    554.439417 |    666.571267 | T. Michael Keesey              |
| 417 |    754.256976 |    657.689800 | Lucas Carbone                  |
| 418 |    250.825329 |    654.409356 | Beth Reinke                    |
| 419 |    345.145766 |    486.391861 | T. Michael Keesey              |
| 420 |    498.584432 |    568.461292 | T. Michael Keesey              |
| 421 |    151.599220 |    204.766606 | Rachael Joakim                 |
| 422 |    157.560289 |    472.434565 | Zimices (Julián Bayona)        |
| 423 |    737.763902 |    381.917240 | T. Michael Keesey              |
| 424 |    355.878433 |    583.886871 | Tasman Dixon                   |
| 425 |    620.673850 |      7.386096 | Gemma Martínez-Redondo         |
| 426 |    767.828887 |    317.604757 | Armin Reindl                   |
| 427 |   1003.401004 |    791.691860 | Zimices (Julián Bayona)        |
| 428 |    172.946819 |    242.517430 | Carlos Cano-Barbacil           |
| 429 |    686.426487 |      7.202199 | Jagged Fang Designs            |
| 430 |    389.158514 |    570.145923 | T. Michael Keesey              |
| 431 |    423.505846 |    329.427974 | Erika Schumacher               |
| 432 |    743.510318 |    168.968481 | T. Michael Keesey              |
| 433 |    676.220650 |    102.083628 | Diana Pomeroy                  |
| 434 |    952.048871 |    660.575615 | seung9park                     |
| 435 |    944.544900 |    233.539219 | Guillaume Dera                 |
| 436 |    760.101966 |    502.707522 | Guillaume Dera                 |
| 437 |    138.692889 |    296.513841 | Markus Grohme                  |
| 438 |    435.038213 |    230.129189 | Andy Wilson                    |
| 439 |    340.213141 |    745.289561 | Mike Taylor                    |
| 440 |    513.778877 |    107.658686 | Guillaume Dera                 |
| 441 |    997.911369 |    230.528990 | T. Michael Keesey              |
| 442 |    125.042868 |    157.044170 | Scott Hartman                  |
| 443 |    484.441319 |    164.129063 | Guillaume Dera                 |
| 444 |    602.477865 |    659.035963 | Steven Traver                  |
| 445 |     27.435724 |    386.683137 | Mason McNair                   |
| 446 |    603.696177 |     93.240708 | T. Michael Keesey              |
| 447 |      9.825692 |    261.182488 | Ricarda Pätsch                 |
| 448 |    693.504584 |    459.078678 | T. Michael Keesey              |
| 449 |     63.493072 |    577.527921 | Alexandre Vong                 |
| 450 |    485.630350 |    503.108679 | maija.karala                   |
| 451 |    799.313634 |    144.967689 | Emily Willoughby e.deinonychus |
| 452 |    682.849813 |    612.225185 | T. Michael Keesey              |
| 453 |    838.838868 |    581.208295 | Andy Wilson                    |
| 454 |     38.278427 |    420.053274 | Jagged Fang Designs            |
| 455 |    717.153353 |    321.038787 | Michelle Site                  |
| 456 |    234.120296 |    528.402330 | Andy Wilson                    |
| 457 |    505.330625 |     45.407238 | Gareth Monger                  |
| 458 |   1008.854231 |    331.078855 | T. Michael Keesey              |
| 459 |    528.469429 |     12.408664 | Matthew Dempsey                |
| 460 |    782.103682 |    450.349992 | monatkat                       |
| 461 |    253.210861 |    395.480215 | Scott Hartman                  |
| 462 |    850.474253 |    404.521679 | Margot Michaud                 |
| 463 |    201.732274 |    238.707228 | T. Michael Keesey              |
| 464 |    348.906609 |    565.874024 | Gareth Monger                  |
| 465 |      7.354475 |    452.250802 | Guillaume Dera                 |
| 466 |     74.839988 |    247.365241 | Melissa Broussard              |
| 467 |     81.462854 |     63.100819 | Guillaume Dera                 |
| 468 |    318.596944 |    198.920255 | Guillaume Dera                 |
| 469 |     16.399872 |    503.592792 | Martin Bulla                   |
| 470 |    448.301067 |    503.503120 | Zimices (Julián Bayona)        |
| 471 |    615.886528 |    206.078546 | Collin Gross                   |
| 472 |    232.856267 |    100.766171 | T. Michael Keesey              |
| 473 |    831.672587 |    627.199370 | Guillaume Dera                 |
| 474 |    984.120329 |     42.636153 | tmccraney                      |
| 475 |    994.058449 |     57.521934 | Markus Grohme                  |
| 476 |    876.803006 |    501.497302 | Tyler Greenfield               |
| 477 |    943.097553 |    575.374008 | Andy Wilson                    |
| 478 |    369.388363 |    695.439806 | Ingo Braasch                   |
| 479 |    787.852625 |    268.462404 | Matthew Crook                  |
| 480 |    443.178601 |    461.207543 | François Michonneau            |
| 481 |     15.944190 |    702.073523 | T. Michael Keesey              |
| 482 |    285.536002 |    780.394792 | Jagged Fang Designs            |
| 483 |   1019.325097 |    260.169611 | Nicolas Bekkouche              |
| 484 |    699.025185 |     61.862495 | Tasman Dixon                   |
| 485 |    710.248301 |    210.544961 | severine Martini               |
| 486 |    569.434635 |    165.691325 | Roberto Diaz Sibaja            |
| 487 |    219.910798 |    459.549837 | Gareth Monger                  |
| 488 |    681.109759 |    497.585185 | Timothée Poisot                |
| 489 |    223.933485 |    372.652310 | ZT Kulik                       |
| 490 |    143.109711 |    103.783824 | Scott Hartman                  |
| 491 |    841.121711 |    796.454932 | Steven Traver                  |
| 492 |    202.357170 |    469.938029 | Andy Wilson                    |
| 493 |    318.566579 |    107.861268 | Guillaume Dera                 |
| 494 |    694.017677 |    774.102688 | T. Michael Keesey              |
| 495 |    676.809022 |    794.922631 | Gareth Monger                  |
| 496 |    803.971482 |    278.677234 | Ferran Sayol                   |
| 497 |    172.463497 |    227.701850 | Andy Wilson                    |
| 498 |    957.595459 |    161.652450 | T. Michael Keesey              |
| 499 |    529.429461 |     23.169142 | Andy Wilson                    |
| 500 |    850.106411 |    788.567828 | Margot Michaud                 |
| 501 |    464.841968 |    177.981106 | Geoff Shaw                     |
| 502 |    277.601337 |    319.990124 | Michelle Site                  |
| 503 |    562.893737 |    126.295682 | Zimices (Julián Bayona)        |
