context("iedriver")

normalizePath <- function(...) base::normalizePath(...)
list.files <- function(...) base::list.files(...)
Sys.info <- function(...) base::Sys.info(...)

test_that("canCallIEDriver", {
  with_mock(
    `binman::process_yaml` = function(...) {},
    `binman::list_versions` = mock_binman_list_versions_iedriver,
    `binman::app_dir` = mock_binman_app_dir,
    normalizePath = mock_base_normalizePath,
    list.files = mock_base_list.files,
    `subprocess::spawn_process` = mock_subprocess_spawn_process,
    `subprocess::process_return_code` =
      mock_subprocess_process_return_code,
    `subprocess::process_kill` = mock_subprocess_process_kill,
    Sys.info = function(...) {
      structure("Windows", .Names = "sysname")
    },
    `wdman:::generic_start_log` = mock_generic_start_log,
    `wdman:::infun_read` = function(...) {
      "infun"
    },
    {
      ieDrv <- iedriver()
      retCommand <- iedriver(retcommand = TRUE)
      expect_identical(ieDrv$output(), "infun")
      expect_identical(ieDrv$error(), "infun")
      logOut <- ieDrv$log()[["stdout"]]
      logErr <- ieDrv$log()[["stderr"]]
      expect_identical(logOut, "super duper")
      expect_identical(logErr, "no error here")
      expect_identical(ieDrv$stop(), "stopped")
    }
  )
  expect_identical(ieDrv$process, "hello")
  expect_true(grepl("some.path /port=4567 /log-level=FATAL", retCommand))
})

test_that("iedriver_verErrorWorks", {
  with_mock(
    `binman::list_versions` = mock_binman_list_versions_iedriver,
    expect_error(
      wdman:::ie_ver("linux64", "noversion"),
      "doesnt match versions"
    )
  )
})

test_that("pickUpErrorFromReturnCode", {
  with_mock(
    `binman::process_yaml` = function(...) {},
    `binman::list_versions` = mock_binman_list_versions_iedriver,
    `binman::app_dir` = mock_binman_app_dir,
    normalizePath = mock_base_normalizePath,
    list.files = mock_base_list.files,
    `subprocess::spawn_process` = mock_subprocess_spawn_process,
    `subprocess::process_return_code` = function(...) {
      "some error"
    },
    `subprocess::process_read` =
      mock_subprocess_process_read_selenium,
    `wdman:::generic_start_log` = mock_generic_start_log,
    Sys.info = function(...) {
      structure("Windows", .Names = "sysname")
    },
    {
      expect_error(
        iedriver(version = "3.0.0"),
        "iedriver couldn't be started"
      )
    }
  )
})

test_that("pickUpErrorFromPortInUse", {
  with_mock(
    `binman::process_yaml` = function(...) {},
    `binman::list_versions` = mock_binman_list_versions_iedriver,
    `binman::app_dir` = mock_binman_app_dir,
    normalizePath = mock_base_normalizePath,
    list.files = mock_base_list.files,
    `subprocess::spawn_process` = mock_subprocess_spawn_process,
    `subprocess::process_return_code` =
      mock_subprocess_process_return_code,
    `subprocess::process_read` =
      mock_subprocess_process_read_selenium,
    `subprocess::process_kill` = mock_subprocess_process_kill,
    `wdman:::generic_start_log` = function(...) {
      list(stderr = "Address in use")
    },
    Sys.info = function(...) {
      structure("Windows", .Names = "sysname")
    },
    {
      expect_error(
        iedriver(version = "3.0.0"),
        "IE Driver signals port"
      )
    }
  )
})
