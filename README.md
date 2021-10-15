
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
library(Rvcg)
library(rgl)
library(rphylopic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Alexandre Vong, Felix Vaux, Ferran Sayol, Didier Descouens (vectorized
by T. Michael Keesey), Zimices, Eduard Solà Vázquez, vectorised by Yan
Wong, Scott Hartman, Gareth Monger, Matt Martyniuk, Sharon
Wegner-Larsen, Chris huh, Steven Traver, Jake Warner, Jagged Fang
Designs, Mathew Wedel, FunkMonk (Michael B. H.), Jaime Headden, Margot
Michaud, L. Shyamal, Brian Swartz (vectorized by T. Michael Keesey),
Matt Crook, Tasman Dixon, Nobu Tamura (vectorized by T. Michael Keesey),
Rebecca Groom, Shyamal, Iain Reid, xgirouxb, Alexander Schmidt-Lebuhn,
Smokeybjb, vectorized by Zimices, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), Milton
Tan, Chase Brownstein, Ghedoghedo, vectorized by Zimices, Kent Elson
Sorgon, Michele M Tobias, James I. Kirkland, Luis Alcalá, Mark A.
Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized
by T. Michael Keesey), T. Michael Keesey, Dmitry Bogdanov, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Mo Hassan, Lauren Anderson,
Jose Carlos Arenas-Monroy, LeonardoG (photography) and T. Michael Keesey
(vectorization), Smokeybjb, Archaeodontosaurus (vectorized by T. Michael
Keesey), Sarah Werning, Carlos Cano-Barbacil, Frank Förster, Stanton F.
Fink (vectorized by T. Michael Keesey), Todd Marshall, vectorized by
Zimices, C. Camilo Julián-Caballero, Tauana J. Cunha, Chris A. Hamilton,
Juan Carlos Jerí, Servien (vectorized by T. Michael Keesey), Andrew A.
Farke, Ben Liebeskind, Jack Mayer Wood, Christine Axon, Dean Schnabel,
Ryan Cupo, Nancy Wyman (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, M Hutchinson, Mattia Menchetti, Gabriela
Palomo-Munoz, Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Dmitry Bogdanov (vectorized by T. Michael Keesey), Michael
Scroggie, Jesús Gómez, vectorized by Zimices, Birgit Lang, Joanna Wolfe,
Ray Simpson (vectorized by T. Michael Keesey), Melissa Broussard, Steven
Coombs, Kailah Thorn & Ben King, T. Michael Keesey (after MPF), Tracy A.
Heath, FunkMonk, Courtney Rockenbach, RS, Matt Celeskey, Smith609 and T.
Michael Keesey, Lauren Sumner-Rooney, Cristina Guijarro, Katie S.
Collins, Tyler McCraney, Estelle Bourdon, Kai R. Caspar, Brad McFeeters
(vectorized by T. Michael Keesey), Mr E? (vectorized by T. Michael
Keesey), Beth Reinke, Jiekun He, Emily Jane McTavish, from Haeckel, E.
H. P. A. (1904).Kunstformen der Natur. Bibliographisches, Conty
(vectorized by T. Michael Keesey), Becky Barnes, Manabu Sakamoto, Sean
McCann, Michael P. Taylor, Julia B McHugh, Kamil S. Jaron, Cesar Julian,
Collin Gross, Neil Kelley, FJDegrange, Michele M Tobias from an image By
Dcrjsr - Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Maxime
Dahirel (digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Allison Pease, Crystal
Maier, Jimmy Bernot, Anthony Caravaggi, Matt Martyniuk (vectorized by T.
Michael Keesey), Steven Haddock • Jellywatch.org, Amanda Katzer, T.
Michael Keesey (vectorization); Yves Bousquet (photography), Mike
Hanson, Sergio A. Muñoz-Gómez, John Conway, Christoph Schomburg, Frank
Denota, François Michonneau, Auckland Museum, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Marie Russell,
Douglas Brown (modified by T. Michael Keesey), Mathilde Cordellier,
Caroline Harding, MAF (vectorized by T. Michael Keesey), David Orr, Lip
Kee Yap (vectorized by T. Michael Keesey), Robbie N. Cada (vectorized by
T. Michael Keesey), Hans Hillewaert (photo) and T. Michael Keesey
(vectorization), Arthur S. Brum, Jay Matternes (vectorized by T. Michael
Keesey), Rafael Maia, Rainer Schoch, Kent Sorgon, Emily Willoughby, T.
Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M.
Townsend & Miguel Vences), Noah Schlottman, photo by Casey Dunn, Andreas
Hejnol, Craig Dylke, Michelle Site, Konsta Happonen, Javier Luque &
Sarah Gerken, Xavier Giroux-Bougard, Mark Witton, Lani Mohan, Giant Blue
Anteater (vectorized by T. Michael Keesey), Tyler Greenfield, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Yan Wong, Benjamint444,
NOAA Great Lakes Environmental Research Laboratory (illustration) and
Timothy J. Bartley (silhouette), Tambja (vectorized by T. Michael
Keesey), Tyler Greenfield and Dean Schnabel, CNZdenek,
SauropodomorphMonarch, Julie Blommaert based on photo by Sofdrakou,
Scott Reid, Ricardo N. Martinez & Oscar A. Alcober, Karkemish
(vectorized by T. Michael Keesey), Martin R. Smith, after Skovsted et al
2015, T. Michael Keesey (after Mauricio Antón), Esme Ashe-Jepson, Kanako
Bessho-Uehara, Ghedoghedo (vectorized by T. Michael Keesey), Pete
Buchholz, Zachary Quigley, Alan Manson (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Armin Reindl, Siobhon
Egan, T. Tischler, Roberto Díaz Sibaja, Ludwik Gasiorowski, , Cagri
Cevrim, Campbell Fleming, Caleb M. Brown, Steven Blackwood, Dianne Bray
/ Museum Victoria (vectorized by T. Michael Keesey), Lukasiniho, DW
Bapst (modified from Bates et al., 2005), Maija Karala, Luis Cunha, Tony
Ayling (vectorized by T. Michael Keesey), Richard J. Harris, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Robert Gay,
Félix Landry Yuan

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    376.284357 |    314.713917 | Alexandre Vong                                                                                                                                              |
|   2 |    638.156323 |    375.384571 | NA                                                                                                                                                          |
|   3 |    147.444935 |    616.485040 | Felix Vaux                                                                                                                                                  |
|   4 |    153.549272 |    407.434068 | Ferran Sayol                                                                                                                                                |
|   5 |    724.712629 |    144.598455 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
|   6 |    712.803967 |    417.712082 | Zimices                                                                                                                                                     |
|   7 |    913.713829 |     80.664708 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                 |
|   8 |    738.945393 |    565.568958 | Zimices                                                                                                                                                     |
|   9 |    470.315331 |    528.639799 | Zimices                                                                                                                                                     |
|  10 |    637.146457 |    760.079070 | Scott Hartman                                                                                                                                               |
|  11 |    598.484551 |    506.694398 | Gareth Monger                                                                                                                                               |
|  12 |    406.593870 |    659.896123 | Matt Martyniuk                                                                                                                                              |
|  13 |    952.905044 |    231.504794 | Sharon Wegner-Larsen                                                                                                                                        |
|  14 |    895.134758 |    748.100683 | Chris huh                                                                                                                                                   |
|  15 |    574.571667 |    648.314514 | Steven Traver                                                                                                                                               |
|  16 |    746.246687 |    699.056994 | Jake Warner                                                                                                                                                 |
|  17 |     82.638138 |     35.747881 | Ferran Sayol                                                                                                                                                |
|  18 |     66.711376 |    154.942356 | Scott Hartman                                                                                                                                               |
|  19 |    340.120880 |    223.336481 | Jagged Fang Designs                                                                                                                                         |
|  20 |    283.743758 |    628.295027 | Mathew Wedel                                                                                                                                                |
|  21 |    246.467765 |    477.205565 | FunkMonk (Michael B. H.)                                                                                                                                    |
|  22 |    372.842944 |    703.555385 | Jaime Headden                                                                                                                                               |
|  23 |    321.212872 |    174.820327 | Margot Michaud                                                                                                                                              |
|  24 |     71.054528 |    691.431406 | L. Shyamal                                                                                                                                                  |
|  25 |    135.689552 |    762.473272 | Chris huh                                                                                                                                                   |
|  26 |    467.576632 |     81.790085 | Jagged Fang Designs                                                                                                                                         |
|  27 |    574.930252 |     58.330122 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                              |
|  28 |    229.559183 |    129.392678 | NA                                                                                                                                                          |
|  29 |    880.514691 |    629.018164 | Matt Crook                                                                                                                                                  |
|  30 |    868.179049 |    533.915029 | Tasman Dixon                                                                                                                                                |
|  31 |     70.119838 |    364.157577 | Matt Crook                                                                                                                                                  |
|  32 |    824.512849 |    330.455788 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  33 |    363.817555 |     69.965110 | Ferran Sayol                                                                                                                                                |
|  34 |    936.698724 |    341.598186 | Rebecca Groom                                                                                                                                               |
|  35 |    558.707204 |    377.049351 | Shyamal                                                                                                                                                     |
|  36 |    249.114917 |    721.535442 | Iain Reid                                                                                                                                                   |
|  37 |    646.768023 |    260.625037 | Steven Traver                                                                                                                                               |
|  38 |    167.382029 |    269.700104 | NA                                                                                                                                                          |
|  39 |    767.895764 |    490.458005 | Mathew Wedel                                                                                                                                                |
|  40 |    393.491345 |    748.372808 | xgirouxb                                                                                                                                                    |
|  41 |    957.499097 |    480.305373 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  42 |     68.198744 |    553.118540 | Matt Crook                                                                                                                                                  |
|  43 |    299.971506 |    570.766965 | Margot Michaud                                                                                                                                              |
|  44 |    485.595983 |    582.909088 | Chris huh                                                                                                                                                   |
|  45 |    841.374926 |    183.577804 | Jagged Fang Designs                                                                                                                                         |
|  46 |     91.716502 |    243.293572 | Smokeybjb, vectorized by Zimices                                                                                                                            |
|  47 |    821.244590 |    254.668864 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
|  48 |    857.185513 |    428.799221 | Milton Tan                                                                                                                                                  |
|  49 |    830.381562 |    378.222772 | Chase Brownstein                                                                                                                                            |
|  50 |    717.044160 |     46.335213 | Zimices                                                                                                                                                     |
|  51 |     32.406571 |    480.147422 | NA                                                                                                                                                          |
|  52 |    931.509906 |    670.183559 | Ghedoghedo, vectorized by Zimices                                                                                                                           |
|  53 |    638.244954 |    609.797739 | Kent Elson Sorgon                                                                                                                                           |
|  54 |    774.553569 |    757.996579 | Margot Michaud                                                                                                                                              |
|  55 |    187.597394 |     91.794621 | Michele M Tobias                                                                                                                                            |
|  56 |    650.557864 |    164.520320 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  57 |    978.876920 |    156.742112 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                        |
|  58 |    555.790047 |    181.694719 | T. Michael Keesey                                                                                                                                           |
|  59 |    760.303161 |    649.148890 | Dmitry Bogdanov                                                                                                                                             |
|  60 |    513.867521 |     26.512853 | Zimices                                                                                                                                                     |
|  61 |     86.020195 |    101.419853 | Tasman Dixon                                                                                                                                                |
|  62 |    579.479518 |    234.159296 | Matt Crook                                                                                                                                                  |
|  63 |    456.336141 |    473.789892 | Gareth Monger                                                                                                                                               |
|  64 |    487.443784 |    782.181648 | Zimices                                                                                                                                                     |
|  65 |    380.682221 |    530.692986 | Margot Michaud                                                                                                                                              |
|  66 |    317.475454 |    140.479534 | Chris huh                                                                                                                                                   |
|  67 |    302.942886 |    259.540344 | Scott Hartman                                                                                                                                               |
|  68 |    272.615148 |    403.539961 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                    |
|  69 |    823.000372 |     75.490119 | Matt Crook                                                                                                                                                  |
|  70 |    595.865182 |     92.851562 | Rebecca Groom                                                                                                                                               |
|  71 |    806.012975 |     28.744093 | Margot Michaud                                                                                                                                              |
|  72 |    541.206027 |    708.517638 | Gareth Monger                                                                                                                                               |
|  73 |    723.248583 |    244.496196 | Mo Hassan                                                                                                                                                   |
|  74 |    847.709864 |    726.410038 | Lauren Anderson                                                                                                                                             |
|  75 |    751.390056 |    524.221314 | Jose Carlos Arenas-Monroy                                                                                                                                   |
|  76 |    236.921899 |    544.837157 | NA                                                                                                                                                          |
|  77 |    535.988895 |    302.804252 | Steven Traver                                                                                                                                               |
|  78 |   1005.408410 |    593.858609 | NA                                                                                                                                                          |
|  79 |    383.399339 |    582.735796 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  80 |    662.784401 |    695.589759 | Margot Michaud                                                                                                                                              |
|  81 |    970.512233 |    411.517822 | Smokeybjb                                                                                                                                                   |
|  82 |    498.108170 |    651.767493 | NA                                                                                                                                                          |
|  83 |    845.477802 |    501.826415 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                        |
|  84 |    688.407106 |    490.340616 | Sarah Werning                                                                                                                                               |
|  85 |    508.514263 |     15.894860 | Scott Hartman                                                                                                                                               |
|  86 |     48.903491 |    187.396744 | Carlos Cano-Barbacil                                                                                                                                        |
|  87 |    439.406197 |     27.189002 | Matt Crook                                                                                                                                                  |
|  88 |    406.578785 |    108.144125 | Frank Förster                                                                                                                                               |
|  89 |    993.362709 |    721.536263 | Margot Michaud                                                                                                                                              |
|  90 |    267.687231 |    768.257540 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                           |
|  91 |    714.265822 |    312.002861 | Todd Marshall, vectorized by Zimices                                                                                                                        |
|  92 |   1018.262146 |    197.594692 | Gareth Monger                                                                                                                                               |
|  93 |    218.704379 |    651.884939 | Ferran Sayol                                                                                                                                                |
|  94 |    340.979980 |    296.772009 | Carlos Cano-Barbacil                                                                                                                                        |
|  95 |    759.739229 |    314.817626 | Michele M Tobias                                                                                                                                            |
|  96 |    288.336515 |     11.945593 | Scott Hartman                                                                                                                                               |
|  97 |    173.698275 |    174.784735 | C. Camilo Julián-Caballero                                                                                                                                  |
|  98 |    852.865918 |     19.666448 | Tauana J. Cunha                                                                                                                                             |
|  99 |    506.532308 |    701.340077 | Jagged Fang Designs                                                                                                                                         |
| 100 |    834.279661 |    144.662102 | Chris A. Hamilton                                                                                                                                           |
| 101 |    974.712429 |    627.233892 | Dmitry Bogdanov                                                                                                                                             |
| 102 |    633.558239 |     25.648201 | Ferran Sayol                                                                                                                                                |
| 103 |    988.151967 |     73.005193 | Juan Carlos Jerí                                                                                                                                            |
| 104 |    181.901494 |    341.658887 | Chris huh                                                                                                                                                   |
| 105 |    956.558018 |    297.648481 | Shyamal                                                                                                                                                     |
| 106 |    932.301495 |    718.177686 | Servien (vectorized by T. Michael Keesey)                                                                                                                   |
| 107 |    413.121407 |    140.178729 | NA                                                                                                                                                          |
| 108 |    477.975844 |    714.718035 | NA                                                                                                                                                          |
| 109 |    276.062688 |    674.128072 | Andrew A. Farke                                                                                                                                             |
| 110 |    715.149886 |    374.632887 | Chris huh                                                                                                                                                   |
| 111 |    839.064398 |     89.164896 | Ben Liebeskind                                                                                                                                              |
| 112 |    957.544390 |    560.769283 | Matt Crook                                                                                                                                                  |
| 113 |    651.378610 |     70.649119 | NA                                                                                                                                                          |
| 114 |    874.281267 |    360.254534 | Jaime Headden                                                                                                                                               |
| 115 |    673.856002 |    195.454644 | Jack Mayer Wood                                                                                                                                             |
| 116 |    288.492662 |    700.314892 | Christine Axon                                                                                                                                              |
| 117 |    899.292628 |    769.381845 | Scott Hartman                                                                                                                                               |
| 118 |    503.994315 |    426.629824 | Dean Schnabel                                                                                                                                               |
| 119 |     34.561869 |    209.630446 | Zimices                                                                                                                                                     |
| 120 |     99.286417 |     77.964150 | Ryan Cupo                                                                                                                                                   |
| 121 |   1006.592746 |    447.538392 | Margot Michaud                                                                                                                                              |
| 122 |    895.703192 |    577.497021 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 123 |    459.100344 |    108.961416 | M Hutchinson                                                                                                                                                |
| 124 |    689.451400 |    559.124896 | T. Michael Keesey                                                                                                                                           |
| 125 |    646.377664 |    549.593224 | Margot Michaud                                                                                                                                              |
| 126 |    372.049554 |    636.628852 | Mattia Menchetti                                                                                                                                            |
| 127 |     69.512362 |    465.084349 | L. Shyamal                                                                                                                                                  |
| 128 |    589.950083 |    708.243520 | NA                                                                                                                                                          |
| 129 |     89.999488 |    790.049340 | Scott Hartman                                                                                                                                               |
| 130 |    290.100704 |    431.057373 | Scott Hartman                                                                                                                                               |
| 131 |    387.126052 |    187.502695 | Margot Michaud                                                                                                                                              |
| 132 |    640.688053 |    446.763395 | Gabriela Palomo-Munoz                                                                                                                                       |
| 133 |    145.174620 |    727.219868 | Chris huh                                                                                                                                                   |
| 134 |    919.870635 |    555.577696 | Matt Crook                                                                                                                                                  |
| 135 |    733.498172 |     66.274583 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                               |
| 136 |    560.274213 |    582.068811 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 137 |    954.961816 |    133.116920 | Michael Scroggie                                                                                                                                            |
| 138 |    992.408282 |    380.377394 | Gabriela Palomo-Munoz                                                                                                                                       |
| 139 |    331.878320 |    492.328702 | Jagged Fang Designs                                                                                                                                         |
| 140 |    211.638698 |    684.362571 | Jesús Gómez, vectorized by Zimices                                                                                                                          |
| 141 |    423.934571 |    625.095059 | Rebecca Groom                                                                                                                                               |
| 142 |    836.706533 |    210.046062 | Birgit Lang                                                                                                                                                 |
| 143 |     21.900042 |    361.855099 | Joanna Wolfe                                                                                                                                                |
| 144 |    978.498050 |     35.245735 | Michele M Tobias                                                                                                                                            |
| 145 |    691.941810 |    734.461602 | Gareth Monger                                                                                                                                               |
| 146 |    572.544367 |    275.509077 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                               |
| 147 |    143.592800 |    337.041153 | Zimices                                                                                                                                                     |
| 148 |    554.783702 |    603.634843 | Melissa Broussard                                                                                                                                           |
| 149 |    588.997064 |    760.705655 | Steven Coombs                                                                                                                                               |
| 150 |    926.556467 |    530.342298 | Chris huh                                                                                                                                                   |
| 151 |     19.281594 |    696.486500 | Michael Scroggie                                                                                                                                            |
| 152 |    794.692347 |    507.254496 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 153 |    344.348148 |    652.728131 | Kailah Thorn & Ben King                                                                                                                                     |
| 154 |    955.670116 |    384.752355 | T. Michael Keesey (after MPF)                                                                                                                               |
| 155 |    247.562816 |    359.120181 | Matt Crook                                                                                                                                                  |
| 156 |    342.211032 |    615.220895 | Gabriela Palomo-Munoz                                                                                                                                       |
| 157 |    853.276819 |    462.697894 | Tasman Dixon                                                                                                                                                |
| 158 |    250.052404 |    431.035881 | Chris huh                                                                                                                                                   |
| 159 |    599.347359 |    302.264026 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 160 |    655.732478 |    570.214689 | Steven Traver                                                                                                                                               |
| 161 |    963.054579 |    591.512665 | Ferran Sayol                                                                                                                                                |
| 162 |    114.480781 |    497.484316 | NA                                                                                                                                                          |
| 163 |    506.582114 |    723.311889 | Ferran Sayol                                                                                                                                                |
| 164 |    166.721471 |    495.326803 | NA                                                                                                                                                          |
| 165 |    179.591849 |    468.293907 | Ferran Sayol                                                                                                                                                |
| 166 |     11.055332 |    220.906089 | NA                                                                                                                                                          |
| 167 |    392.940169 |    795.012070 | Zimices                                                                                                                                                     |
| 168 |    652.905333 |    527.072989 | Tracy A. Heath                                                                                                                                              |
| 169 |    607.956755 |     19.380640 | Rebecca Groom                                                                                                                                               |
| 170 |    905.780262 |    381.107538 | FunkMonk                                                                                                                                                    |
| 171 |   1006.618929 |    194.316977 | T. Michael Keesey                                                                                                                                           |
| 172 |    688.749485 |    200.245434 | Jaime Headden                                                                                                                                               |
| 173 |    749.292233 |     89.995337 | Courtney Rockenbach                                                                                                                                         |
| 174 |    126.342315 |    124.564058 | Tasman Dixon                                                                                                                                                |
| 175 |    748.655382 |     16.274480 | RS                                                                                                                                                          |
| 176 |    249.209681 |    376.295713 | Jagged Fang Designs                                                                                                                                         |
| 177 |    861.208241 |    399.750411 | Zimices                                                                                                                                                     |
| 178 |     15.350867 |    645.583194 | Matt Celeskey                                                                                                                                               |
| 179 |    450.914200 |    616.227023 | NA                                                                                                                                                          |
| 180 |    327.302926 |    258.543719 | C. Camilo Julián-Caballero                                                                                                                                  |
| 181 |    926.652957 |    280.236203 | Tauana J. Cunha                                                                                                                                             |
| 182 |    148.805411 |     42.181472 | Smith609 and T. Michael Keesey                                                                                                                              |
| 183 |    243.193073 |    743.921074 | Scott Hartman                                                                                                                                               |
| 184 |   1007.447996 |    683.001928 | Matt Crook                                                                                                                                                  |
| 185 |    209.555525 |    395.159310 | NA                                                                                                                                                          |
| 186 |    545.643064 |    483.722839 | Gabriela Palomo-Munoz                                                                                                                                       |
| 187 |    361.410456 |    104.457075 | Margot Michaud                                                                                                                                              |
| 188 |    284.446843 |    607.171067 | Matt Crook                                                                                                                                                  |
| 189 |    172.735602 |    726.436125 | Zimices                                                                                                                                                     |
| 190 |    337.610151 |    469.301975 | Gabriela Palomo-Munoz                                                                                                                                       |
| 191 |   1006.072611 |    265.777664 | Lauren Sumner-Rooney                                                                                                                                        |
| 192 |    142.034805 |     85.104227 | Tasman Dixon                                                                                                                                                |
| 193 |    867.924035 |    211.713923 | Ferran Sayol                                                                                                                                                |
| 194 |    510.245216 |     83.772919 | Zimices                                                                                                                                                     |
| 195 |    506.131488 |    481.267252 | Cristina Guijarro                                                                                                                                           |
| 196 |     62.566690 |    615.058245 | T. Michael Keesey                                                                                                                                           |
| 197 |    520.472197 |    748.634942 | Katie S. Collins                                                                                                                                            |
| 198 |    935.142729 |    784.793384 | NA                                                                                                                                                          |
| 199 |    682.243424 |    222.857119 | T. Michael Keesey                                                                                                                                           |
| 200 |    896.155927 |    147.408251 | Dmitry Bogdanov                                                                                                                                             |
| 201 |    283.925659 |     69.622871 | Tyler McCraney                                                                                                                                              |
| 202 |     54.574710 |    316.538447 | NA                                                                                                                                                          |
| 203 |    499.623444 |    429.473052 | Zimices                                                                                                                                                     |
| 204 |    996.438586 |    771.809541 | Matt Crook                                                                                                                                                  |
| 205 |    863.151034 |    690.685067 | Estelle Bourdon                                                                                                                                             |
| 206 |    916.043285 |     26.223708 | Kai R. Caspar                                                                                                                                               |
| 207 |    784.148953 |    631.300418 | Ferran Sayol                                                                                                                                                |
| 208 |    527.587000 |    397.225939 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                            |
| 209 |    151.314600 |    153.043531 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
| 210 |    532.818886 |    171.541974 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                     |
| 211 |     17.663238 |    557.778618 | Scott Hartman                                                                                                                                               |
| 212 |    785.721957 |    418.829579 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 213 |    881.280438 |    723.794822 | Matt Crook                                                                                                                                                  |
| 214 |    498.502426 |    329.919242 | Zimices                                                                                                                                                     |
| 215 |    676.310363 |    663.951918 | Chris huh                                                                                                                                                   |
| 216 |    740.468332 |    289.631092 | NA                                                                                                                                                          |
| 217 |    180.173533 |    791.836046 | Zimices                                                                                                                                                     |
| 218 |    992.378996 |    544.319642 | Beth Reinke                                                                                                                                                 |
| 219 |     30.330880 |    748.071993 | Jiekun He                                                                                                                                                   |
| 220 |    407.801109 |    474.299717 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                              |
| 221 |     60.755756 |     70.267226 | Conty (vectorized by T. Michael Keesey)                                                                                                                     |
| 222 |    220.742248 |    776.941289 | Gareth Monger                                                                                                                                               |
| 223 |    719.994278 |    522.546750 | NA                                                                                                                                                          |
| 224 |    489.122710 |    606.792718 | Becky Barnes                                                                                                                                                |
| 225 |    566.324122 |    330.345959 | Manabu Sakamoto                                                                                                                                             |
| 226 |    699.803890 |     17.769952 | Jaime Headden                                                                                                                                               |
| 227 |     82.996482 |    483.908601 | Matt Crook                                                                                                                                                  |
| 228 |   1005.823633 |     20.731949 | Sean McCann                                                                                                                                                 |
| 229 |    846.687845 |    787.681280 | Katie S. Collins                                                                                                                                            |
| 230 |    818.167637 |    580.897563 | Jaime Headden                                                                                                                                               |
| 231 |    303.312229 |     31.225632 | Michael P. Taylor                                                                                                                                           |
| 232 |    405.879360 |     61.272850 | Julia B McHugh                                                                                                                                              |
| 233 |    573.531023 |    120.500167 | Ferran Sayol                                                                                                                                                |
| 234 |    485.728288 |    303.773181 | Kamil S. Jaron                                                                                                                                              |
| 235 |    706.264628 |    345.340379 | Cesar Julian                                                                                                                                                |
| 236 |    584.172389 |    182.522069 | L. Shyamal                                                                                                                                                  |
| 237 |    410.631761 |     10.201111 | Collin Gross                                                                                                                                                |
| 238 |    885.283658 |    239.587985 | Scott Hartman                                                                                                                                               |
| 239 |    374.294249 |    231.246125 | Matt Crook                                                                                                                                                  |
| 240 |    597.407467 |    139.151599 | Neil Kelley                                                                                                                                                 |
| 241 |    889.174405 |    546.574433 | NA                                                                                                                                                          |
| 242 |    371.405488 |    260.230463 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 243 |    896.005849 |    353.134010 | FJDegrange                                                                                                                                                  |
| 244 |     16.292695 |    779.148188 | Zimices                                                                                                                                                     |
| 245 |    838.742394 |    224.535682 | Chris huh                                                                                                                                                   |
| 246 |    727.621019 |     23.096351 | Scott Hartman                                                                                                                                               |
| 247 |    633.566820 |    307.132841 | NA                                                                                                                                                          |
| 248 |    877.779569 |    195.883708 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>                                  |
| 249 |    815.729912 |    620.929437 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                  |
| 250 |    799.887910 |    453.128931 | Allison Pease                                                                                                                                               |
| 251 |    587.179215 |    420.757939 | Crystal Maier                                                                                                                                               |
| 252 |    767.741159 |    178.060610 | Jimmy Bernot                                                                                                                                                |
| 253 |    234.025575 |    248.283516 | Anthony Caravaggi                                                                                                                                           |
| 254 |    866.060812 |    586.446808 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 255 |    207.523461 |     58.774080 | T. Michael Keesey                                                                                                                                           |
| 256 |     20.939649 |    123.910033 | Steven Traver                                                                                                                                               |
| 257 |    158.664504 |    200.664614 | NA                                                                                                                                                          |
| 258 |    583.275106 |     36.675253 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 259 |    799.185252 |    552.286807 | Sarah Werning                                                                                                                                               |
| 260 |     11.463856 |     47.989452 | Ferran Sayol                                                                                                                                                |
| 261 |     64.168059 |    126.774226 | Amanda Katzer                                                                                                                                               |
| 262 |    907.443020 |    499.238959 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                              |
| 263 |    131.752813 |    474.290405 | Collin Gross                                                                                                                                                |
| 264 |     38.464151 |    405.971462 | Matt Crook                                                                                                                                                  |
| 265 |    565.917457 |    766.329182 | Mike Hanson                                                                                                                                                 |
| 266 |   1007.083511 |    312.069421 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 267 |    113.937215 |    442.817412 | Zimices                                                                                                                                                     |
| 268 |    274.111252 |    203.761953 | John Conway                                                                                                                                                 |
| 269 |     10.221680 |    310.282228 | Christoph Schomburg                                                                                                                                         |
| 270 |    314.498012 |     43.060691 | Jagged Fang Designs                                                                                                                                         |
| 271 |    146.084359 |    222.215207 | Rebecca Groom                                                                                                                                               |
| 272 |    686.726084 |    590.862295 | Frank Denota                                                                                                                                                |
| 273 |    786.369068 |    304.324610 | François Michonneau                                                                                                                                         |
| 274 |    311.311928 |    782.980398 | Jagged Fang Designs                                                                                                                                         |
| 275 |    288.287356 |    242.929517 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 276 |    556.726688 |    456.637485 | Birgit Lang                                                                                                                                                 |
| 277 |    626.306411 |    717.733569 | T. Michael Keesey                                                                                                                                           |
| 278 |    327.014713 |    661.679214 | NA                                                                                                                                                          |
| 279 |    239.757482 |    646.293877 | Auckland Museum                                                                                                                                             |
| 280 |    925.147911 |    123.996921 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 281 |    472.291550 |    648.490522 | Zimices                                                                                                                                                     |
| 282 |    900.936731 |    453.175736 | Marie Russell                                                                                                                                               |
| 283 |    510.706208 |    114.245531 | Gabriela Palomo-Munoz                                                                                                                                       |
| 284 |    102.306719 |    786.223292 | Jagged Fang Designs                                                                                                                                         |
| 285 |    197.616990 |    371.805979 | Jagged Fang Designs                                                                                                                                         |
| 286 |    713.875836 |    719.986444 | Douglas Brown (modified by T. Michael Keesey)                                                                                                               |
| 287 |    700.903998 |    617.156651 | Mathilde Cordellier                                                                                                                                         |
| 288 |    942.091736 |     10.003809 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                     |
| 289 |    950.891731 |    701.089340 | Steven Traver                                                                                                                                               |
| 290 |    918.329054 |    627.562887 | David Orr                                                                                                                                                   |
| 291 |     16.617597 |    263.803656 | Juan Carlos Jerí                                                                                                                                            |
| 292 |    465.789069 |     55.733580 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                               |
| 293 |    668.886499 |    323.215402 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 294 |    108.530337 |    461.951237 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 295 |    293.094944 |     82.865979 | Andrew A. Farke                                                                                                                                             |
| 296 |    341.581513 |    326.766856 | Birgit Lang                                                                                                                                                 |
| 297 |    771.653827 |    271.558349 | Gabriela Palomo-Munoz                                                                                                                                       |
| 298 |    791.510787 |    658.248056 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                            |
| 299 |     92.955882 |    188.485139 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                               |
| 300 |    232.598698 |    581.052242 | Arthur S. Brum                                                                                                                                              |
| 301 |    484.684268 |    549.125205 | Zimices                                                                                                                                                     |
| 302 |    729.786886 |    326.804405 | Chris huh                                                                                                                                                   |
| 303 |    997.473085 |    516.482069 | Ferran Sayol                                                                                                                                                |
| 304 |    820.268958 |    714.431188 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                             |
| 305 |     74.846899 |    582.274198 | Shyamal                                                                                                                                                     |
| 306 |    895.297580 |    702.555339 | Dean Schnabel                                                                                                                                               |
| 307 |     65.466156 |    372.791189 | Gareth Monger                                                                                                                                               |
| 308 |    965.188544 |    747.968699 | Rafael Maia                                                                                                                                                 |
| 309 |    344.910628 |    784.774995 | Matt Crook                                                                                                                                                  |
| 310 |    274.093124 |    732.428299 | Rainer Schoch                                                                                                                                               |
| 311 |     54.546477 |    349.708833 | Kent Sorgon                                                                                                                                                 |
| 312 |    474.712703 |    683.505496 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 313 |    907.131567 |    270.884805 | Zimices                                                                                                                                                     |
| 314 |    899.294014 |     12.136298 | Emily Willoughby                                                                                                                                            |
| 315 |    890.978666 |    785.508325 | Steven Traver                                                                                                                                               |
| 316 |    894.799599 |    402.959936 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 317 |    882.984957 |    497.159470 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                           |
| 318 |    328.715441 |    506.628240 | Noah Schlottman, photo by Casey Dunn                                                                                                                        |
| 319 |    959.442170 |    176.600602 | Andreas Hejnol                                                                                                                                              |
| 320 |    353.999272 |    247.421587 | Scott Hartman                                                                                                                                               |
| 321 |    684.426519 |    649.664785 | Craig Dylke                                                                                                                                                 |
| 322 |    909.368494 |    135.705954 | Gareth Monger                                                                                                                                               |
| 323 |    252.542728 |    264.599111 | Michelle Site                                                                                                                                               |
| 324 |    103.723443 |    352.616870 | Margot Michaud                                                                                                                                              |
| 325 |    230.199442 |    340.007631 | Konsta Happonen                                                                                                                                             |
| 326 |    268.432304 |     92.705228 | Javier Luque & Sarah Gerken                                                                                                                                 |
| 327 |    112.118042 |    425.310032 | Xavier Giroux-Bougard                                                                                                                                       |
| 328 |    102.109227 |    371.069510 | NA                                                                                                                                                          |
| 329 |     54.267650 |      6.151866 | Scott Hartman                                                                                                                                               |
| 330 |    965.195143 |    770.598335 | Jaime Headden                                                                                                                                               |
| 331 |     15.319299 |    240.635683 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 332 |    500.212528 |    347.680685 | Jagged Fang Designs                                                                                                                                         |
| 333 |    163.929032 |     65.027135 | Gareth Monger                                                                                                                                               |
| 334 |    789.415619 |    188.599048 | Joanna Wolfe                                                                                                                                                |
| 335 |   1003.030958 |    336.375742 | Christoph Schomburg                                                                                                                                         |
| 336 |    131.564324 |    491.971896 | Jack Mayer Wood                                                                                                                                             |
| 337 |    957.699982 |    108.082582 | Zimices                                                                                                                                                     |
| 338 |    183.166003 |    432.511130 | Matt Martyniuk                                                                                                                                              |
| 339 |    214.535337 |    429.085968 | Mark Witton                                                                                                                                                 |
| 340 |    669.761879 |    368.250574 | Beth Reinke                                                                                                                                                 |
| 341 |    443.708369 |    569.305800 | Smokeybjb                                                                                                                                                   |
| 342 |    271.745014 |    219.539612 | Ferran Sayol                                                                                                                                                |
| 343 |   1007.623554 |    422.144672 | Zimices                                                                                                                                                     |
| 344 |     79.443188 |    438.377387 | Jose Carlos Arenas-Monroy                                                                                                                                   |
| 345 |    108.368087 |    126.836855 | T. Michael Keesey                                                                                                                                           |
| 346 |    786.782762 |    683.116928 | Chris huh                                                                                                                                                   |
| 347 |    205.234621 |     29.237661 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 348 |    611.831682 |    579.088162 | T. Michael Keesey                                                                                                                                           |
| 349 |    157.357035 |    106.838833 | Lani Mohan                                                                                                                                                  |
| 350 |    108.360225 |    722.781638 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 351 |    130.168032 |    791.408988 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                       |
| 352 |    165.619942 |    443.498939 | Gareth Monger                                                                                                                                               |
| 353 |    890.211843 |    470.329648 | Sarah Werning                                                                                                                                               |
| 354 |    415.872990 |     85.026483 | Jagged Fang Designs                                                                                                                                         |
| 355 |    319.011361 |    535.618884 | Michael P. Taylor                                                                                                                                           |
| 356 |    710.127527 |    269.605854 | Emily Willoughby                                                                                                                                            |
| 357 |    134.285841 |    417.795808 | Tyler Greenfield                                                                                                                                            |
| 358 |    812.842252 |    643.799412 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                            |
| 359 |    589.484500 |    572.345005 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                       |
| 360 |    764.469047 |     41.376118 | Yan Wong                                                                                                                                                    |
| 361 |    808.219701 |    463.137155 | Yan Wong                                                                                                                                                    |
| 362 |     70.059930 |    511.141756 | Benjamint444                                                                                                                                                |
| 363 |    273.149571 |     42.286679 | Beth Reinke                                                                                                                                                 |
| 364 |    207.122072 |    362.951917 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                       |
| 365 |     27.236436 |      9.054658 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 366 |     46.683096 |    335.980274 | Amanda Katzer                                                                                                                                               |
| 367 |     74.045413 |    641.295949 | Ferran Sayol                                                                                                                                                |
| 368 |    875.632737 |    671.778686 | Tambja (vectorized by T. Michael Keesey)                                                                                                                    |
| 369 |    545.315494 |    432.734480 | Tyler Greenfield and Dean Schnabel                                                                                                                          |
| 370 |    615.504262 |    125.689153 | Christoph Schomburg                                                                                                                                         |
| 371 |    412.463593 |    588.239164 | Matt Crook                                                                                                                                                  |
| 372 |    335.781422 |    601.108756 | NA                                                                                                                                                          |
| 373 |     33.990454 |    255.965214 | T. Michael Keesey                                                                                                                                           |
| 374 |    515.950765 |    768.421427 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 375 |    428.970186 |    103.469377 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 376 |    889.159999 |    111.138284 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 377 |     74.945250 |    299.436555 | Gareth Monger                                                                                                                                               |
| 378 |    532.665450 |    567.850809 | NA                                                                                                                                                          |
| 379 |    139.322901 |    265.693258 | Jaime Headden                                                                                                                                               |
| 380 |    677.782388 |    639.315185 | CNZdenek                                                                                                                                                    |
| 381 |     32.100390 |     72.869602 | Todd Marshall, vectorized by Zimices                                                                                                                        |
| 382 |    273.541722 |    177.528683 | SauropodomorphMonarch                                                                                                                                       |
| 383 |    119.059030 |    181.962351 | Margot Michaud                                                                                                                                              |
| 384 |    551.501849 |    739.616399 | Chris huh                                                                                                                                                   |
| 385 |    191.112698 |      7.849589 | Sarah Werning                                                                                                                                               |
| 386 |    662.915688 |    730.722460 | NA                                                                                                                                                          |
| 387 |    996.586479 |    154.180679 | T. Michael Keesey                                                                                                                                           |
| 388 |    169.753593 |    529.773274 | Julie Blommaert based on photo by Sofdrakou                                                                                                                 |
| 389 |    299.054879 |     59.469111 | Tasman Dixon                                                                                                                                                |
| 390 |    599.528500 |    264.461122 | Gareth Monger                                                                                                                                               |
| 391 |    385.084907 |      8.835140 | Scott Reid                                                                                                                                                  |
| 392 |    780.413985 |    494.503002 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                      |
| 393 |    801.948514 |    213.250600 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                 |
| 394 |    302.860385 |    517.270451 | Sarah Werning                                                                                                                                               |
| 395 |    190.965153 |    407.183091 | Carlos Cano-Barbacil                                                                                                                                        |
| 396 |    861.418179 |    603.720922 | Gabriela Palomo-Munoz                                                                                                                                       |
| 397 |    837.999800 |    625.175170 | NA                                                                                                                                                          |
| 398 |    707.594700 |      4.241774 | NA                                                                                                                                                          |
| 399 |    635.953456 |    646.716923 | Michelle Site                                                                                                                                               |
| 400 |    697.176350 |    669.970820 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 401 |    441.028077 |    689.035714 | Dean Schnabel                                                                                                                                               |
| 402 |    464.391041 |    725.524364 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 403 |    439.597423 |    650.401202 | Margot Michaud                                                                                                                                              |
| 404 |    372.886546 |    617.998937 | T. Michael Keesey                                                                                                                                           |
| 405 |    312.994459 |    615.742572 | Birgit Lang                                                                                                                                                 |
| 406 |    156.876255 |    128.261503 | Martin R. Smith, after Skovsted et al 2015                                                                                                                  |
| 407 |    979.480609 |    273.242046 | Zimices                                                                                                                                                     |
| 408 |     82.803460 |    172.782552 | Ferran Sayol                                                                                                                                                |
| 409 |    350.396743 |     24.295790 | Tasman Dixon                                                                                                                                                |
| 410 |   1006.045595 |    663.230238 | T. Michael Keesey (after Mauricio Antón)                                                                                                                    |
| 411 |    981.815877 |    571.815766 | Mathew Wedel                                                                                                                                                |
| 412 |    146.006350 |      5.009134 | NA                                                                                                                                                          |
| 413 |    386.796055 |    145.149140 | Esme Ashe-Jepson                                                                                                                                            |
| 414 |    887.676605 |    250.557352 | NA                                                                                                                                                          |
| 415 |    519.152746 |    235.761210 | Kanako Bessho-Uehara                                                                                                                                        |
| 416 |    127.858494 |    228.141338 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 417 |    824.247385 |    695.606361 | Smokeybjb                                                                                                                                                   |
| 418 |    943.474363 |    175.512410 | NA                                                                                                                                                          |
| 419 |    309.752719 |    726.811052 | Pete Buchholz                                                                                                                                               |
| 420 |     60.521679 |    792.592237 | Collin Gross                                                                                                                                                |
| 421 |    483.225148 |    101.910308 | NA                                                                                                                                                          |
| 422 |   1010.349159 |    120.598495 | NA                                                                                                                                                          |
| 423 |    158.993760 |    797.787769 | Zachary Quigley                                                                                                                                             |
| 424 |     44.859232 |    126.617680 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 425 |    540.286415 |    505.747803 | Mattia Menchetti                                                                                                                                            |
| 426 |    883.953875 |    483.349276 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 427 |     45.573423 |    713.028243 | Armin Reindl                                                                                                                                                |
| 428 |    360.285721 |    515.702627 | Tasman Dixon                                                                                                                                                |
| 429 |    225.458089 |     18.182139 | Sarah Werning                                                                                                                                               |
| 430 |    637.926673 |    656.657294 | Scott Hartman                                                                                                                                               |
| 431 |    468.780485 |    704.383627 | Chris huh                                                                                                                                                   |
| 432 |    196.416685 |    195.535554 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 433 |    341.996087 |     97.875990 | Siobhon Egan                                                                                                                                                |
| 434 |   1004.689903 |    285.397505 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                              |
| 435 |    649.612593 |    218.936099 | Ryan Cupo                                                                                                                                                   |
| 436 |    707.295313 |    599.123236 | Jack Mayer Wood                                                                                                                                             |
| 437 |    564.482943 |    697.740218 | T. Michael Keesey                                                                                                                                           |
| 438 |    806.936499 |      8.077828 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 439 |    761.231679 |     27.002310 | T. Tischler                                                                                                                                                 |
| 440 |   1001.784957 |      6.230918 | Zimices                                                                                                                                                     |
| 441 |    620.110074 |      4.066100 | Margot Michaud                                                                                                                                              |
| 442 |    867.978908 |    161.570774 | Roberto Díaz Sibaja                                                                                                                                         |
| 443 |     80.903405 |    354.947227 | Alexander Schmidt-Lebuhn                                                                                                                                    |
| 444 |      8.184118 |    537.314615 | Ludwik Gasiorowski                                                                                                                                          |
| 445 |    270.654703 |    789.793171 |                                                                                                                                                             |
| 446 |     72.785036 |    279.672411 | T. Michael Keesey                                                                                                                                           |
| 447 |    892.007836 |    684.017277 | Steven Traver                                                                                                                                               |
| 448 |    781.310023 |    290.265609 | Anthony Caravaggi                                                                                                                                           |
| 449 |    762.676304 |    386.381287 | Scott Hartman                                                                                                                                               |
| 450 |    398.297545 |    501.286976 | Gareth Monger                                                                                                                                               |
| 451 |    246.929565 |    699.545693 | Mathew Wedel                                                                                                                                                |
| 452 |    685.904691 |     81.186333 | Jagged Fang Designs                                                                                                                                         |
| 453 |    538.808724 |    239.768952 | Cagri Cevrim                                                                                                                                                |
| 454 |    820.920887 |    773.064909 | Chris huh                                                                                                                                                   |
| 455 |    770.496140 |      5.613825 | Mike Hanson                                                                                                                                                 |
| 456 |    161.549905 |    514.023790 | Christoph Schomburg                                                                                                                                         |
| 457 |    825.506227 |    604.441281 | NA                                                                                                                                                          |
| 458 |    763.839469 |    196.862175 | Jaime Headden                                                                                                                                               |
| 459 |    606.355138 |    317.274560 | Smokeybjb                                                                                                                                                   |
| 460 |    638.579513 |    792.460720 | Tasman Dixon                                                                                                                                                |
| 461 |    837.719508 |    454.997740 | Steven Traver                                                                                                                                               |
| 462 |    661.503646 |    509.403579 | Campbell Fleming                                                                                                                                            |
| 463 |      9.787172 |     92.868551 | NA                                                                                                                                                          |
| 464 |    787.736297 |    158.616718 | Jagged Fang Designs                                                                                                                                         |
| 465 |    581.319446 |    727.703567 | Scott Hartman                                                                                                                                               |
| 466 |    520.806324 |    692.193412 | Zimices                                                                                                                                                     |
| 467 |    388.101311 |    654.840883 | Caleb M. Brown                                                                                                                                              |
| 468 |     26.781612 |    282.424407 | Steven Blackwood                                                                                                                                            |
| 469 |    631.665127 |    731.906316 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                             |
| 470 |    745.805697 |    461.352806 | Lukasiniho                                                                                                                                                  |
| 471 |    357.522777 |    791.951607 | Chris huh                                                                                                                                                   |
| 472 |    129.142269 |    170.552373 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                           |
| 473 |    580.161087 |    795.264262 | Zimices                                                                                                                                                     |
| 474 |    265.242530 |    195.378099 | Chris huh                                                                                                                                                   |
| 475 |    535.304002 |    661.153605 | Matt Crook                                                                                                                                                  |
| 476 |    110.579892 |      6.972705 | Rebecca Groom                                                                                                                                               |
| 477 |    838.147043 |    604.010376 | DW Bapst (modified from Bates et al., 2005)                                                                                                                 |
| 478 |    638.423028 |    686.032452 | Matt Crook                                                                                                                                                  |
| 479 |    317.154644 |    647.946116 | Rebecca Groom                                                                                                                                               |
| 480 |    546.446600 |     78.320006 | Maija Karala                                                                                                                                                |
| 481 |    546.807007 |    548.462041 | Luis Cunha                                                                                                                                                  |
| 482 |    439.241090 |    125.852149 | Iain Reid                                                                                                                                                   |
| 483 |    268.409346 |     64.706152 | Dean Schnabel                                                                                                                                               |
| 484 |    476.494185 |    665.211155 | Carlos Cano-Barbacil                                                                                                                                        |
| 485 |     22.025830 |     26.280216 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 486 |    872.684810 |     92.591808 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 487 |    589.635975 |      7.667934 | Zimices                                                                                                                                                     |
| 488 |    672.815618 |    297.570459 | Gareth Monger                                                                                                                                               |
| 489 |     17.245211 |    626.576516 | Richard J. Harris                                                                                                                                           |
| 490 |    506.056679 |     60.281864 | Chase Brownstein                                                                                                                                            |
| 491 |    416.657140 |    439.915463 | John Conway                                                                                                                                                 |
| 492 |    246.835985 |    280.458616 | Emily Willoughby                                                                                                                                            |
| 493 |    206.278477 |    730.782020 | Scott Hartman                                                                                                                                               |
| 494 |    355.836185 |     12.577553 | Steven Traver                                                                                                                                               |
| 495 |     27.330504 |    308.692176 | François Michonneau                                                                                                                                         |
| 496 |    273.776797 |    168.567483 | Cesar Julian                                                                                                                                                |
| 497 |    955.367400 |     17.188935 | Gareth Monger                                                                                                                                               |
| 498 |    528.027322 |    409.545347 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                            |
| 499 |    999.208494 |    219.839472 | Mathew Wedel                                                                                                                                                |
| 500 |    612.314335 |    183.346243 | Scott Hartman                                                                                                                                               |
| 501 |    432.287018 |     55.753531 | Tasman Dixon                                                                                                                                                |
| 502 |    322.052756 |    424.992067 | NA                                                                                                                                                          |
| 503 |    339.768737 |    312.932492 | Jaime Headden                                                                                                                                               |
| 504 |    443.556868 |    718.294663 | Zimices                                                                                                                                                     |
| 505 |    936.029947 |    153.209031 | NA                                                                                                                                                          |
| 506 |    407.604393 |    177.428878 | T. Michael Keesey                                                                                                                                           |
| 507 |    505.010302 |    255.814962 | NA                                                                                                                                                          |
| 508 |    844.818937 |     57.645379 | Steven Traver                                                                                                                                               |
| 509 |    520.593835 |     98.191825 | Robert Gay                                                                                                                                                  |
| 510 |   1000.315816 |    749.434383 | Dmitry Bogdanov                                                                                                                                             |
| 511 |    736.432834 |    536.310371 | Jaime Headden                                                                                                                                               |
| 512 |    232.956191 |    795.580095 | Chris huh                                                                                                                                                   |
| 513 |    738.577491 |    220.588760 | Félix Landry Yuan                                                                                                                                           |

    #> Your tweet has been posted!
